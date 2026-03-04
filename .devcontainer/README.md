# Devcontainer Configuration

This directory contains shared devcontainer infrastructure. Two files need to be created manually (both are gitignored).

## 1. `config.local`

Per-user configuration. Controls Claude authentication and which profile runs at startup.

```bash
# Required
CLAUDE_AUTH_MODE=browser    # "browser" (OAuth login) or "api-key" (from 1Password)
PROFILE=default             # Profile script to run: profiles/{PROFILE}.sh

# Only when using 1Password (deploy keys or api-key auth):
# OP_SERVICE_ACCOUNT_TOKEN=ops_your_token_here
```

### Common setups

**Browser login + host SSH** (simplest — no 1Password needed):
```
CLAUDE_AUTH_MODE=browser
PROFILE=default
```

**Browser login + deploy key** (Claude Teams + SSH isolation):
```
CLAUDE_AUTH_MODE=browser
PROFILE=yourname
OP_SERVICE_ACCOUNT_TOKEN=ops_...
```

**API key + deploy key** (full isolation):
```
CLAUDE_AUTH_MODE=api-key
PROFILE=yourname
OP_SERVICE_ACCOUNT_TOKEN=ops_...
```

## 2. `gitconfig.personal`

Your git identity for commits made inside the container.

```ini
[user]
    name = Claude (for Your Name)
    email = you+claude@example.com
```

## Profiles

Profile scripts in `profiles/` run at container startup after shared setup. They control per-user configuration like SSH method and dotfiles.

- `profiles/default.sh` — uses host SSH agent forwarding (no setup needed)
- To use a deploy key: create `profiles/yourname.sh` that calls `scripts/configure-git-ssh.sh`
- See `profiles/justin.sh` for an example

## Full Documentation

For security model, troubleshooting, key rotation, and setup scripts:
https://github.com/AICarePatron/devcontainers
