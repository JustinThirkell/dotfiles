FROM node:24

ARG TZ
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=latest

# Install basic development tools, iptables/ipset, and dependencies for 1Password CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  curl \
  ca-certificates \
  locales \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
  locale-gen
ENV LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

# Install 1Password CLI (Linux version for container)
RUN curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
  tee /etc/apt/sources.list.d/1password.list && \
  apt-get update && \
  apt-get install -y 1password-cli && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Rename default node user to containeruser for clarity
ARG USERNAME=containeruser
RUN usermod -l containeruser -d /home/containeruser -m node && \
  groupmod -n containeruser node

# Ensure containeruser has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R containeruser:containeruser /usr/local/share

# Persist bash history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set DEVCONTAINER environment variable
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/containeruser/.claude && \
  chown -R containeruser:containeruser /workspace /home/containeruser/.claude

WORKDIR /workspace

# Install git-delta for better diffs
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Install entire CLI (git-native task tracking for autonomous agents)
ARG ENTIRE_VERSION=0.4.4
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/entireio/cli/releases/download/v${ENTIRE_VERSION}/entire_linux_${ARCH}.tar.gz" && \
  tar -xzf "entire_linux_${ARCH}.tar.gz" entire && \
  mv entire /usr/local/bin/entire && \
  chmod +x /usr/local/bin/entire && \
  rm "entire_linux_${ARCH}.tar.gz"

# Set up non-root user
USER containeruser

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh
ENV SHELL=/bin/zsh

# Set the default editor
ENV EDITOR=nano
ENV VISUAL=nano

# Install zsh theme and configuration
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Install Claude Code (native installer, replaces deprecated npm method)
RUN curl -fsSL https://claude.ai/install.sh | bash -s ${CLAUDE_CODE_VERSION}
ENV PATH="/home/containeruser/.local/bin:$PATH"

# Create Claude config directory (settings.json will be copied by postStartCommand)
RUN mkdir -p /home/containeruser/.claude

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "containeruser ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/containeruser-firewall && \
  chmod 0440 /etc/sudoers.d/containeruser-firewall
USER containeruser