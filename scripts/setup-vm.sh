#!/bin/bash
# setup-vm.sh — One-shot VM setup for Miles Agent
#
# Usage:
#   Step 1 (from local): ./scripts/push-to-vm.sh   (copies files to VM)
#   Step 2 (on VM):      ./setup-vm.sh             (installs everything)
#
# This script runs ON the VM after files have been pushed.
# It installs Docker, creates the directory structure, sets permissions,
# generates the vault deploy key, and prepares OpenClaw for first start.
#
# Prerequisites:
#   - push-to-vm.sh has been run successfully
#   - ~/miles-staging/ directory exists with all files

set -euo pipefail

echo "=== Miles Agent — VM Setup ==="
echo "Running on: $(hostname)"
echo "Date: $(date)"
echo ""

# ─── Step 1: Install Docker Engine ───
echo "--- Step 1: Installing Docker Engine ---"
if command -v docker &>/dev/null; then
    echo "  Docker already installed: $(docker --version)"
else
    sudo apt-get update -qq
    sudo apt-get install -y -qq ca-certificates curl

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

    sudo usermod -aG docker openclaw
    echo "  Docker installed. NOTE: You may need to log out and back in for group changes."
fi
echo ""

# ─── Step 2: Install GoG CLI ───
echo "--- Step 2: Installing GoG CLI ---"
if command -v gog &>/dev/null; then
    echo "  GoG already installed: $(gog --version 2>&1 | head -1)"
else
    curl -fsSL https://github.com/koki-develop/gog/releases/latest/download/gog_linux_amd64.tar.gz | sudo tar xz -C /usr/local/bin gog
    echo "  GoG installed: $(gog --version 2>&1 | head -1)"
fi
echo ""

# ─── Step 3: Create directory structure ───
echo "--- Step 3: Creating directory structure ---"
mkdir -p ~/miles/{workspace/skills,workspace/daily,workspace/logs}
mkdir -p ~/.openclaw
mkdir -p ~/.config/systemd/user
echo "  Directories created."
echo ""

# ─── Step 4: Move staged files into place ───
echo "--- Step 4: Deploying configuration files ---"
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

# Skills → workspace/skills
cp "$STAGING/skills/"*.md ~/miles/workspace/skills/
echo "  Skills deployed: $(ls ~/miles/workspace/skills/*.md | wc -l) files"

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

# ─── Step 5: Create docker-compose.yml ───
echo "--- Step 5: Creating docker-compose.yml ---"
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
    ports: []
    security_opt:
      - no-new-privileges:true
    read_only: false
    tmpfs:
      - /tmp:size=100M
COMPOSE_EOF
echo "  docker-compose.yml created"
echo ""

# ─── Step 6: Generate vault deploy key ───
echo "--- Step 6: Generating vault deploy key ---"
if [ -f ~/.ssh/vault_deploy_key ]; then
    echo "  Deploy key already exists. Skipping."
else
    ssh-keygen -t ed25519 -C "miles-vm-vault-deploy" -f ~/.ssh/vault_deploy_key -N ""
    echo "  Deploy key generated."
fi
echo ""
echo "  ┌─────────────────────────────────────────────────┐"
echo "  │ ACTION REQUIRED: Add this public key to GitHub  │"
echo "  │ https://github.com/andrewjoiner/vault/settings/keys │"
echo "  │ Title: miles-vm-vault-deploy                    │"
echo "  │ Allow write access: YES                         │"
echo "  └─────────────────────────────────────────────────┘"
echo ""
echo "  Public key:"
cat ~/.ssh/vault_deploy_key.pub
echo ""

# Configure SSH for GitHub
if ! grep -q "github.com-miles-vault" ~/.ssh/config 2>/dev/null; then
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

# ─── Step 7: Install vault-sync systemd units ───
echo "--- Step 7: Installing vault-sync systemd units ---"

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

# ─── Step 8: Enable lingering ───
echo "--- Step 8: Enabling systemd lingering ---"
sudo loginctl enable-linger openclaw
systemctl --user daemon-reload
echo "  Lingering enabled, systemd reloaded"
echo ""

# ─── Step 9: Copy auth-profiles.json from Ava (if reachable) ───
echo "--- Step 9: Auth profiles ---"
echo "  auth-profiles.json must be copied from Ava's VM."
echo "  After setup, run:"
echo "    scp ava-vm:~/.openclaw/auth-profiles.json ~/.openclaw/auth-profiles.json"
echo "    chmod 600 ~/.openclaw/auth-profiles.json"
echo ""

# ─── Summary ───
echo "========================================"
echo "  Miles VM Setup Complete"
echo "========================================"
echo ""
echo "Remaining manual steps:"
echo "  1. Add vault deploy key to GitHub (see public key above)"
echo "  2. Clone vault: git clone git@github.com-miles-vault:andrewjoiner/vault.git ~/work-vault"
echo "  3. Copy auth-profiles.json from Ava VM"
echo "  4. Fill in Azure AI Foundry endpoint in openclaw.json"
echo "  5. Run Google Calendar OAuth: gog auth login --account andrew@wastenaut.ai"
echo "  6. Log out and back in (for Docker group), then: cd ~/miles && docker compose up -d"
echo "  7. Verify model: docker exec miles-openclaw openclaw status | grep model"
echo "  8. Test Telegram: send 'Hello Miles' to @miles_chief_bot"
echo ""
echo "DO NOT enable heartbeat until Telegram is confirmed working."
