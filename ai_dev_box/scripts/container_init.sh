#!/bin/bash
# Container initialization script for ai-dev-box
# Run inside the container as root to set up the environment
set -euo pipefail

USERNAME="$1"
USER_UID="$2"
USER_GID="$3"
USER_HOME="$4"

log() { echo "[ai-dev-box] $*"; }

log "Initializing container for user $USERNAME (uid=$USER_UID, gid=$USER_GID)"

# ── Base packages ──────────────────────────────────────────────────────────────
log "Updating apt and installing base packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q \
    python3 \
    python3-venv \
    python3-pip \
    python3-dev \
    pipx \
    git \
    curl \
    wget \
    build-essential \
    ca-certificates \
    gnupg \
    sudo \
    bash-completion \
    locales \
    unzip \
    zip \
    jq \
    htop \
    vim \
    nano \
    file \
    lsb-release \
    xdg-utils \
    socat \
    netcat-openbsd

# ── Locale ─────────────────────────────────────────────────────────────────────
log "Setting up locale..."
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# ── Node.js via NodeSource ─────────────────────────────────────────────────────
log "Installing Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y -q nodejs
npm install -g npm@latest

# ── User setup ─────────────────────────────────────────────────────────────────
log "Setting up user $USERNAME..."

# Create group if it doesn't exist
if ! getent group "$USER_GID" >/dev/null 2>&1; then
    groupadd -g "$USER_GID" "$USERNAME"
fi

# Create user if it doesn't exist
if ! id "$USERNAME" >/dev/null 2>&1; then
    useradd \
        --uid "$USER_UID" \
        --gid "$USER_GID" \
        --shell /bin/bash \
        --no-create-home \
        --home-dir "$USER_HOME" \
        "$USERNAME"
fi

# Passwordless sudo
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"
chmod 0440 "/etc/sudoers.d/${USERNAME}"

# ── Bun ────────────────────────────────────────────────────────────────────────
log "Installing Bun..."
sudo -u "$USERNAME" bash -c \
    'curl -fsSL https://bun.sh/install | bash' \
    || log "Warning: Bun install failed (non-fatal)"

# ── Homebrew (Linuxbrew) ───────────────────────────────────────────────────────
log "Installing Homebrew..."
sudo -u "$USERNAME" bash -c \
    'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' \
    || log "Warning: Homebrew install failed (non-fatal)"

# ── Profile / bashrc setup ────────────────────────────────────────────────────
log "Writing shell profile additions..."
PROFILE_SNIPPET="/etc/profile.d/ai-dev-box.sh"
cat > "$PROFILE_SNIPPET" <<'PROFILE'
# ai-dev-box environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Homebrew
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Bun
if [ -d "$HOME/.bun" ]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# pipx
export PATH="$PATH:$HOME/.local/bin"

# lemonade / ollama already at localhost - no override needed (proxy handles it)
PROFILE

log "Container initialization complete!"
log "User $USERNAME is ready inside the container."
