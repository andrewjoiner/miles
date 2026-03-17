#!/bin/bash
# setup-vm.sh — One-shot VM setup for Miles Agent
#
# Usage:
#   Step 1 (from local): ./scripts/push-to-vm.sh   (copies files to VM)
#   Step 2 (on VM):      ./setup-vm.sh             (installs everything)
#
# This script runs ON the VM after files have been pushed.
# It installs Docker, OpenClaw, ClawHub skills, creates the directory structure,
# sets permissions, generates the vault deploy key, and prepares for first start.
#
# Prerequisites:
#   - push-to-vm.sh has been run successfully
#   - ~/miles-staging/ directory exists with all files

set -euo pipefail

echo "=== Miles Agent — VM Setup ==="
echo "Running on: $(hostname)"
echo "Date: $(date)"
echo ""

# ─── Step 1: System Dependencies ───
echo "--- Step 1: Installing system dependencies ---"
sudo apt-get update -qq
sudo apt-get install -y -qq ca-certificates curl git jq
echo "  System deps installed."
echo ""

# ─── Step 2: Install Docker Engine ───
echo "--- Step 2: Installing Docker Engine ---"
if command -v docker &>/dev/null; then
    echo "  Docker already installed: $(docker --version)"
else
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

    sudo usermod -aG docker openclaw
    echo "  Docker installed. NOTE: Log out and back in for group changes to take effect."
fi
echo ""

# ─── Step 3: Install Node.js (NVM) + OpenClaw ───
echo "--- Step 3: Installing Node.js and OpenClaw ---"
if command -v openclaw &>/dev/null; then
    echo "  OpenClaw already installed: $(openclaw --version 2>&1 | head -1)"
else
    # Install NVM
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    # Install Node LTS
    nvm install --lts
    nvm use --lts

    # Install OpenClaw
    npm install -g openclaw@latest
    echo "  OpenClaw installed: $(openclaw --version 2>&1 | head -1)"
fi

# Ensure NVM is loaded for the rest of the script
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
echo ""

# ─── Step 4: Install ClawHub CLI ───
echo "--- Step 4: Installing ClawHub CLI ---"
if command -v clawhub &>/dev/null; then
    echo "  ClawHub already installed."
else
    npm install -g clawhub@latest
    echo "  ClawHub CLI installed."
fi
echo ""

# ─── Step 5: Create directory structure ───
echo "--- Step 5: Creating directory structure ---"
mkdir -p ~/miles/{workspace/skills,workspace/daily,workspace/logs}
mkdir -p ~/.openclaw/skills
mkdir -p ~/.config/systemd/user
echo "  Directories created."
echo ""

# ─── Step 6: Deploy staged files ───
echo "--- Step 6: Deploying configuration files ---"
STAGING=~/miles-staging

if [ ! -d "$STAGING" ]; then
    echo "  ERROR: ~/miles-staging/ not found. Run push-to-vm.sh first."
    exit 1
fi

# .env → ~/miles/.env
cp "$STAGING/staging.env" ~/miles/.env
chmod 600 ~/miles/.env
echo "  .env deployed (permissions 600)"

# openclaw.json → ~/miles/openclaw.json
cp "$STAGING/openclaw.json" ~/miles/openclaw.json
chmod 600 ~/miles/openclaw.json
echo "  openclaw.json deployed (permissions 600)"

# Agent config templates → workspace
cp "$STAGING/templates/soul.md.template" ~/miles/workspace/SOUL.md
cp "$STAGING/templates/agents.md.template" ~/miles/workspace/AGENTS.md
cp "$STAGING/templates/user.md.template" ~/miles/workspace/USER.md
cp "$STAGING/templates/tools.md.template" ~/miles/workspace/TOOLS.md
cp "$STAGING/templates/heartbeat.md.template" ~/miles/workspace/HEARTBEAT.md
cp "$STAGING/templates/security-rules.md.template" ~/miles/workspace/SECURITY.md
echo "  Agent config files deployed to workspace"

# Custom skills → workspace/skills
cp "$STAGING/skills/"*.md ~/miles/workspace/skills/
echo "  Custom skills deployed: $(ls ~/miles/workspace/skills/*.md | wc -l) files"

# client_secret.json → ~/.openclaw/
if [ -f "$STAGING/client_secret.json" ]; then
    cp "$STAGING/client_secret.json" ~/.openclaw/client_secret.json
    chmod 600 ~/.openclaw/client_secret.json
    echo "  client_secret.json deployed (permissions 600)"
else
    echo "  SKIP: client_secret.json not found in staging"
fi

# Initialize MEMORY.md
printf "# Memory — Miles\n\nNo observations yet. This file will be populated as the daily observation cycle runs during the shadow period.\n" > ~/miles/workspace/MEMORY.md
echo "  MEMORY.md initialized"
echo ""

# ─── Step 7: Install ClawHub Skills ───
echo "--- Step 7: Installing ClawHub skills ---"
echo ""

# V1 Skills — install now
echo "  Installing V1 skills..."

# self-improving: captures learnings, errors, corrections. Tiered memory (HOT/WARM/COLD).
# Replaces our custom memory-writer with a more structured approach.
echo "  [1/5] self-improving (learning + memory)..."
clawhub install self-improving --workdir ~/miles/workspace 2>&1 | tail -1 || echo "    WARN: self-improving install failed — will retry manually"

# gog: Google Workspace CLI — Gmail, Calendar, Drive, Contacts, Sheets, Docs.
# Bundled with OpenClaw but clawhub ensures latest version.
echo "  [2/5] gog (Google Workspace)..."
clawhub install gog --workdir ~/miles/workspace 2>&1 | tail -1 || echo "    WARN: gog install failed — bundled version will be used"

# obsidian: Obsidian vault integration via obsidian-cli.
# Complements our custom vault-observer skill with CLI tooling.
echo "  [3/5] obsidian (vault integration)..."
clawhub install obsidian --workdir ~/miles/workspace 2>&1 | tail -1 || echo "    WARN: obsidian install failed — will retry manually"

# filesystem: file operations on local filesystem.
# Needed for vault reads and memory writes.
echo "  [4/5] filesystem..."
clawhub install filesystem --workdir ~/miles/workspace 2>&1 | tail -1 || echo "    WARN: filesystem install failed — will retry manually"

# auto-updater: daily cron to update OpenClaw + skills automatically.
echo "  [5/5] auto-updater..."
clawhub install auto-updater --workdir ~/miles/workspace 2>&1 | tail -1 || echo "    WARN: auto-updater install failed — will retry manually"

echo ""
echo "  V1 skills installed."
echo ""

# List all installed skills
echo "  Installed skills:"
ls ~/miles/workspace/skills/ 2>/dev/null || echo "    (none found — check installation)"
echo ""

# Note: These skills are deferred to later phases
echo "  Deferred skills (install when needed):"
echo "    V2: gmail, mcporter, google-meet, ontology"
echo "    V3: playwright (prospect research)"
echo "    V4: automation-workflows (Cowork migration)"
echo ""

# ─── Step 8: Create docker-compose.yml ───
echo "--- Step 8: Creating docker-compose.yml ---"
cat > ~/miles/docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  miles-openclaw:
    image: openclaw/openclaw:latest
    container_name: miles-openclaw
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - ./workspace:/home/openclaw/.openclaw/workspace
      - ./openclaw.json:/home/openclaw/.openclaw/openclaw.json:ro
      - /home/openclaw/work-vault:/home/openclaw/work-vault:ro
    ports: []
    security_opt:
      - no-new-privileges:true
    read_only: false
    tmpfs:
      - /tmp:size=100M
COMPOSE_EOF
echo "  docker-compose.yml created (includes work-vault mount)"
echo ""

# ─── Step 9: Generate vault deploy key ───
echo "--- Step 9: Generating vault deploy key ---"
if [ -f ~/.ssh/vault_deploy_key ]; then
    echo "  Deploy key already exists. Skipping."
else
    ssh-keygen -t ed25519 -C "miles-vm-vault-deploy" -f ~/.ssh/vault_deploy_key -N ""
    echo "  Deploy key generated."
fi
echo ""
echo "  ┌──────────────────────────────────────────────────────┐"
echo "  │ ACTION REQUIRED: Add this public key to GitHub       │"
echo "  │ https://github.com/andrewjoiner/vault/settings/keys  │"
echo "  │ Title: miles-vm-vault-deploy                         │"
echo "  │ Allow write access: YES                              │"
echo "  └──────────────────────────────────────────────────────┘"
echo ""
echo "  Public key:"
cat ~/.ssh/vault_deploy_key.pub
echo ""

# Configure SSH for GitHub
if ! grep -q "github.com-miles-vault" ~/.ssh/config 2>/dev/null; then
    mkdir -p ~/.ssh
    cat >> ~/.ssh/config << 'SSH_EOF'

Host github.com-miles-vault
    HostName github.com
    User git
    IdentityFile ~/.ssh/vault_deploy_key
    IdentitiesOnly yes
SSH_EOF
    chmod 600 ~/.ssh/config
    echo "  SSH config for GitHub updated"
fi
echo ""

# ─── Step 10: Install vault-sync systemd units ───
echo "--- Step 10: Installing vault-sync systemd units ---"

cat > ~/.config/systemd/user/vault-sync.service << 'SVC_EOF'
[Unit]
Description=Work Vault git sync (pull + push Miles Outputs)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=/home/openclaw/work-vault
ExecStart=/bin/bash -c '\
  git pull --rebase --autostash origin main 2>&1 && \
  if git status --porcelain "Miles Outputs/" | grep -q .; then \
    git add "Miles Outputs/" && \
    git commit -m "miles: vault sync $(date +%%Y-%%m-%%d\\ %%H:%%M)" && \
    git push origin main 2>&1; \
  fi'

[Install]
WantedBy=default.target
SVC_EOF

cat > ~/.config/systemd/user/vault-sync.timer << 'TMR_EOF'
[Unit]
Description=Work Vault sync timer (every 10 minutes)

[Timer]
OnBootSec=2min
OnUnitActiveSec=10min
Persistent=true

[Install]
WantedBy=timers.target
TMR_EOF

echo "  Systemd units installed"
echo ""

# ─── Step 11: Enable lingering ───
echo "--- Step 11: Enabling systemd lingering ---"
sudo loginctl enable-linger openclaw
systemctl --user daemon-reload
echo "  Lingering enabled, systemd reloaded"
echo ""

# ─── Step 12: Auth profiles ───
echo "--- Step 12: Auth profiles ---"
echo "  auth-profiles.json must be copied from Ava's VM (same Azure AI Foundry key)."
echo "  After setup, run:"
echo "    scp ava-vm:~/.openclaw/auth-profiles.json ~/.openclaw/auth-profiles.json"
echo "    chmod 600 ~/.openclaw/auth-profiles.json"
echo ""

# ─── Summary ───
echo "════════════════════════════════════════════════════════"
echo "  Miles VM Setup Complete"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Remaining manual steps (in order):"
echo ""
echo "  1. Add vault deploy key to GitHub (public key shown above)"
echo "     https://github.com/andrewjoiner/vault/settings/keys"
echo ""
echo "  2. Clone the Work Vault:"
echo "     git clone git@github.com-miles-vault:andrewjoiner/vault.git ~/work-vault"
echo "     cd ~/work-vault && git config user.name 'Miles Agent' && git config user.email 'miles@wastenaut.ai'"
echo "     mkdir -p ~/work-vault/'Miles Outputs'"
echo ""
echo "  3. Enable vault-sync timer:"
echo "     systemctl --user enable vault-sync.timer && systemctl --user start vault-sync.timer"
echo ""
echo "  4. Copy auth-profiles.json from Ava's VM:"
echo "     scp ava-vm:~/.openclaw/auth-profiles.json ~/.openclaw/auth-profiles.json"
echo "     chmod 600 ~/.openclaw/auth-profiles.json"
echo ""
echo "  5. Google Calendar OAuth (requires browser):"
echo "     export GOG_CLIENT_SECRET_PATH=~/.openclaw/client_secret.json"
echo "     gog auth login --account andrew@wastenaut.ai"
echo "     gog auth login --account drew.joiner@gmail.com"
echo ""
echo "  6. Log out and back in (for Docker group), then start OpenClaw:"
echo "     cd ~/miles && docker compose up -d"
echo ""
echo "  7. CRITICAL — Verify model is NOT Opus:"
echo "     docker exec miles-openclaw openclaw status | grep model"
echo ""
echo "  8. Test Telegram: send 'Hello Miles' to @miles_chief_bot"
echo ""
echo "  DO NOT enable heartbeat until Telegram is confirmed working."
echo ""
echo "  To enable heartbeat later, edit ~/miles/openclaw.json:"
echo "    \"heartbeat\": { \"enabled\": true, \"intervalMinutes\": 1440 }"
echo "    Then: cd ~/miles && docker compose restart"
