#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Base Firewall Script — generated into .devcontainer/init-firewall.sh by init-devcontainer.sh.
# Do not run this directly; use the generated script in your repo.

# ============================================================================
# Logging Utilities (self-contained — no external dependencies)
# ============================================================================
debug_log() { [ "${DEBUG_DEVCONTAINER:-false}" = "true" ] && echo "[DEBUG] $*" >&2 || true; }
info_log()  { echo "[INFO] $*" >&2; }
warn_log()  { echo "[WARN] $*" >&2; }
error_log() { echo "[ERROR] $*" >&2; }

# ============================================================================
# Main Script
# ============================================================================
info_log "Starting firewall configuration..."

# Extract Docker DNS info BEFORE any flushing
debug_log "Extracting Docker DNS rules..."
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

# Reset default policies to ACCEPT before flushing (a previous failed run may
# have left DROP policies in place, which would block DNS/curl during setup)
debug_log "Resetting default policies to ACCEPT..."
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Flush existing rules and delete existing ipsets
debug_log "Flushing existing iptables rules..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
debug_log "Destroying existing ipsets..."
ipset destroy github-api 2>/dev/null || true
ipset destroy github-git 2>/dev/null || true
ipset destroy allowed-domains 2>/dev/null || true

# Selectively restore ONLY internal Docker DNS resolution
if [ -n "$DOCKER_DNS_RULES" ]; then
    info_log "Restoring Docker DNS rules..."
    iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
    iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
    echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
else
    debug_log "No Docker DNS rules to restore"
fi

# Allow DNS and localhost before restrictions
debug_log "Setting up basic allow rules (DNS, localhost)..."
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# ============================================================================
# GitHub IP ranges (fetched before DROP policy is applied)
# ============================================================================

info_log "Fetching GitHub IP ranges..."
gh_ranges=$(curl -s https://api.github.com/meta 2>&1)
curl_exit=$?
if [ $curl_exit -ne 0 ]; then
    error_log "Failed to fetch GitHub IP ranges (curl exit code: $curl_exit)"
    error_log "Output: $gh_ranges"
    exit 1
fi

if [ -z "$gh_ranges" ]; then
    error_log "Failed to fetch GitHub IP ranges (empty response)"
    exit 1
fi

if ! echo "$gh_ranges" | jq -e '.api and .git' >/dev/null 2>&1; then
    error_log "GitHub API response missing required fields"
    error_log "Response: $gh_ranges"
    exit 1
fi

# GitHub API ipset — port 443 only (for gh CLI: pr create, issue create, etc.)
debug_log "Creating github-api ipset..."
ipset create github-api hash:net
GH_API_COUNT=0
while read -r cidr; do
    if [[ ! "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        error_log "Invalid CIDR range from GitHub meta (api): $cidr"
        exit 1
    fi
    ipset add github-api "$cidr"
    GH_API_COUNT=$((GH_API_COUNT + 1))
done < <(echo "$gh_ranges" | jq -r '.api[] | select(contains(":") | not)')
iptables -A OUTPUT -m set --match-set github-api dst -p tcp --dport 443 -j ACCEPT
info_log "Added $GH_API_COUNT GitHub API CIDR ranges (port 443)"

# GitHub git ipset — port 22 only (for SSH push/pull with deploy key)
debug_log "Creating github-git ipset..."
ipset create github-git hash:net
GH_GIT_COUNT=0
while read -r cidr; do
    if [[ ! "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        error_log "Invalid CIDR range from GitHub meta (git): $cidr"
        exit 1
    fi
    ipset add github-git "$cidr"
    GH_GIT_COUNT=$((GH_GIT_COUNT + 1))
done < <(echo "$gh_ranges" | jq -r '.git[] | select(contains(":") | not)')
iptables -A OUTPUT -m set --match-set github-git dst -p tcp --dport 22 -j ACCEPT
info_log "Added $GH_GIT_COUNT GitHub git CIDR ranges (port 22)"

# Note: .web ranges (github.com HTTPS, raw.githubusercontent.com) are intentionally
# excluded — not required for devcontainer operations. If gh CLI auth fails, add
# .web ranges to github-api as a fallback.

# ============================================================================
# General allowed-domains ipset (resolved via DNS)
# ============================================================================

debug_log "Creating ipset for allowed domains..."
ipset create allowed-domains hash:net

# Resolve and add allowed domains
# DOMAINS_PLACEHOLDER — replaced by init-devcontainer.sh with actual domain list
info_log "Resolving and allowlisting domains..."
for domain in "my.1password.com" "api.anthropic.com" "claude.ai" "auth.anthropic.com" "registry.npmjs.org" "registry.yarnpkg.com" ; do
    debug_log "Resolving $domain..."
    ips=$(dig +noall +answer +time=3 +tries=1 A "$domain" 2>/dev/null | awk '$4 == "A" {print $5}' || true)
    if [ -z "$ips" ]; then
        debug_log "WARNING: Failed to resolve $domain (may not be critical)"
        continue
    fi

    IP_COUNT=0
    while read -r ip; do
        if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            error_log "Invalid IP from DNS for $domain: $ip"
            exit 1
        fi
        debug_log "Adding $ip for $domain"
        ipset add allowed-domains "$ip" 2>/dev/null || true
        IP_COUNT=$((IP_COUNT + 1))
    done < <(echo "$ips")
    info_log "✓ Allowlisted $domain ($IP_COUNT IPs)"
done

# Allow outbound HTTPS to allowed domains (port 443)
iptables -A OUTPUT -m set --match-set allowed-domains dst -p tcp --dport 443 -j ACCEPT

# ============================================================================
# Host network access
# ============================================================================

# Get host IP from default route
debug_log "Detecting host network..."
HOST_IP=$(ip route | grep default | cut -d" " -f3)
if [ -z "$HOST_IP" ]; then
    error_log "Failed to detect host IP"
    exit 1
fi

HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
info_log "Host network detected: $HOST_NETWORK"

debug_log "Allowing host network access..."
iptables -A INPUT -s "$HOST_NETWORK" -j ACCEPT
iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT

# ============================================================================
# Default DROP policy + established connections
# ============================================================================

debug_log "Setting default policies to DROP..."
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

debug_log "Allowing established connections..."
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Explicitly REJECT remaining outbound traffic
debug_log "Setting up reject rule for all other traffic..."
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

info_log "Firewall configuration complete"

# ============================================================================
# Firewall Verification
# ============================================================================

info_log "Verifying firewall rules..."

# Verify firewall blocks unauthorized domains
debug_log "Testing block of unauthorized domain (example.com)..."
if curl --connect-timeout 5 https://example.com >/dev/null 2>&1; then
    error_log "Firewall verification failed - was able to reach https://example.com"
    exit 1
else
    info_log "✓ Firewall blocks unauthorized domains (example.com)"
fi

# Verify GitHub API access
debug_log "Testing GitHub API access..."
if ! curl --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1; then
    error_log "Firewall verification failed - unable to reach https://api.github.com"
    exit 1
else
    info_log "✓ GitHub API access verified"
fi

# Verify 1Password API access
debug_log "Testing 1Password API access..."
if ! curl --connect-timeout 5 -I https://my.1password.com >/dev/null 2>&1; then
    debug_log "WARNING: Unable to verify 1Password API access (may use different region)"
    info_log "⚠ 1Password API access not verified (may be using different region)"
else
    info_log "✓ 1Password API access verified"
fi

info_log "Firewall setup complete and verified"
debug_log "Total allowed-domains ipset entries: $(ipset list allowed-domains | grep -c '^[0-9]' || echo 0)"
