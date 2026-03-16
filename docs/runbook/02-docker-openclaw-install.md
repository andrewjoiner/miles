# 02 — Docker & OpenClaw Installation

## Install Docker Engine

SSH into the VM:
```bash
ssh miles-vm
```

Install Docker Engine (apt, NOT snap, NOT Docker Desktop):
```bash
# Add Docker's official GPG key and repo
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add openclaw user to docker group (avoid sudo for docker commands)
sudo usermod -aG docker openclaw
```

Log out and back in for group change to take effect:
```bash
exit
ssh miles-vm
docker --version
```

## Create Miles's Directory Structure

```bash
mkdir -p ~/miles/{workspace/skills,workspace/daily,workspace/logs}
```

## Create .env File

```bash
cat > ~/miles/.env << 'EOF'
ANTHROPIC_API_KEY=your-key-here
TELEGRAM_BOT_TOKEN=your-bot-token-here
APOLLO_API_KEY=your-apollo-key-here
TODOIST_API_TOKEN=your-todoist-token-here
EOF

chmod 600 ~/miles/.env
```

## Create docker-compose.yml

```bash
cat > ~/miles/docker-compose.yml << 'EOF'
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
    ports: []  # No ports exposed — localhost only inside container
    security_opt:
      - no-new-privileges:true
    read_only: false  # Workspace needs to be writable for memory/logs
    tmpfs:
      - /tmp:size=100M
EOF
```

## Copy OpenClaw Config

Copy the filled `openclaw.json` (from `config/openclaw.json.template` with values filled in):
```bash
# From local machine:
scp "config/openclaw.json" miles-vm:~/miles/openclaw.json
```

## Copy Agent Configuration Files

```bash
# From local machine — copy filled templates to workspace:
scp config/templates/soul.md.template miles-vm:~/miles/workspace/SOUL.md
scp config/templates/agents.md.template miles-vm:~/miles/workspace/AGENTS.md
scp config/templates/user.md.template miles-vm:~/miles/workspace/USER.md
scp config/templates/tools.md.template miles-vm:~/miles/workspace/TOOLS.md
scp config/templates/heartbeat.md.template miles-vm:~/miles/workspace/HEARTBEAT.md
scp config/templates/security-rules.md.template miles-vm:~/miles/workspace/SECURITY.md
```

## Copy Skills

```bash
scp skills/*.md miles-vm:~/miles/workspace/skills/
```

## Initialize Memory

```bash
ssh miles-vm 'printf "# Memory — Miles\n\nNo observations yet. This file will be populated as the daily observation cycle runs during the shadow period.\n" > ~/miles/workspace/MEMORY.md'
```

## Start OpenClaw

```bash
ssh miles-vm "cd ~/miles && docker compose up -d"
```

## Verify

```bash
# Check container is running
ssh miles-vm "docker ps | grep miles-openclaw"

# Check logs for startup
ssh miles-vm "docker logs miles-openclaw --tail 20"

# CRITICAL: Verify model is NOT Opus
ssh miles-vm "docker exec miles-openclaw openclaw status | grep model"
```

**If model shows Opus:** Stop immediately and fix openclaw.json. Do not proceed until model is confirmed as Haiku.

## IMMEDIATELY After First Start

1. Verify model is Haiku (see above)
2. Verify heartbeat is DISABLED in openclaw.json
3. Do NOT send any test messages until Telegram is configured (Step 04)
