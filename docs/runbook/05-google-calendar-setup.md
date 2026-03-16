# 05 — Google Calendar Setup (GoG CLI)

## Overview
Miles uses GoG CLI for direct Google Calendar access. No n8n middleware — this is a lesson learned from Ava's setup. Direct CLI calls are simpler and more reliable.

## Install GoG CLI on VM

```bash
ssh miles-vm

# Install GoG (Google Calendar CLI)
# Check latest release at https://github.com/koki-develop/gog
curl -fsSL https://github.com/koki-develop/gog/releases/latest/download/gog_linux_amd64.tar.gz | sudo tar xz -C /usr/local/bin gog

# Verify installation
gog --version
```

## Set Up OAuth2 Client

If reusing the Google Cloud project from Ava:
1. The `client_secret.json` already exists — copy it to the VM
```bash
# From local machine (copy from Ava's VM or local backup):
scp ~/.credentials/client_secret.json miles-vm:~/.openclaw/client_secret.json
ssh miles-vm "chmod 600 ~/.openclaw/client_secret.json"
```

If creating a new project:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create project: **"Miles Agent"** (or reuse Ava's project)
3. Enable the **Google Calendar API**
4. APIs & Services → Credentials → Create OAuth 2.0 Client ID
5. Application type: **Desktop application**
6. Download `client_secret.json`, copy to VM

## Authorize Accounts

### Work Calendar (Full Access)
```bash
ssh miles-vm
export GOG_CLIENT_SECRET_PATH=~/.openclaw/client_secret.json
gog auth login --account andrew@wastenaut.ai
```
Follow the OAuth flow in your browser. This grants full read/write access to the work calendar.

### Family Calendar (Read-Only, Opaque)
```bash
gog auth login --account drew.joiner@gmail.com
```
Follow the OAuth flow. This grants read access — Miles will strip content and show only time blocks.

## Set Up Keyring Password

GoG stores OAuth tokens in an encrypted keyring. Set the password:
```bash
# Generate a keyring password
KEYRING_PW=$(openssl rand -base64 32)

# Store it
echo "GOG_KEYRING_PASSWORD=$KEYRING_PW" >> ~/.openclaw/.env
echo "$KEYRING_PW" > ~/.openclaw/.gog_keyring_pw
chmod 600 ~/.openclaw/.env ~/.openclaw/.gog_keyring_pw

# Set default account to work calendar
echo "GOG_ACCOUNT=andrew@wastenaut.ai" >> ~/.openclaw/.env
```

## Systemd Environment Override

Create a systemd drop-in config so GoG environment variables are available to the OpenClaw gateway:

```bash
mkdir -p ~/.config/systemd/user/openclaw-gateway.service.d

cat > ~/.config/systemd/user/openclaw-gateway.service.d/env.conf << EOF
[Service]
Environment="GOG_KEYRING_PASSWORD=$(cat ~/.openclaw/.gog_keyring_pw)"
Environment="GOG_ACCOUNT=andrew@wastenaut.ai"
Environment="GOG_CLIENT_SECRET_PATH=/home/openclaw/.openclaw/client_secret.json"
EOF

chmod 600 ~/.config/systemd/user/openclaw-gateway.service.d/env.conf
systemctl --user daemon-reload
```

## Test Calendar Access

```bash
# Test work calendar (should show full event details)
GOG_KEYRING_PASSWORD=$(cat ~/.openclaw/.gog_keyring_pw) \
GOG_ACCOUNT=andrew@wastenaut.ai \
gog calendar list --from $(date +%Y-%m-%d) --to $(date -d '+7 days' +%Y-%m-%d) --plain

# Test family calendar (should show events — Miles will strip content in the skill)
GOG_KEYRING_PASSWORD=$(cat ~/.openclaw/.gog_keyring_pw) \
GOG_ACCOUNT=drew.joiner@gmail.com \
gog calendar list --from $(date +%Y-%m-%d) --to $(date -d '+7 days' +%Y-%m-%d) --plain
```

Verify:
- Work calendar shows full event titles and details
- Family calendar shows events (privacy stripping happens at the agent level in calendar-observer skill)

## OAuth Token Refresh Notes
- GoG handles token refresh automatically using the stored refresh token
- OAuth app in "Testing" mode — tokens may expire after 7 days
- If auth fails (401), re-run `gog auth login` for the affected account
- Consider publishing the OAuth app for longer-lived tokens once stable

## Privacy Notes
- **Work calendar (andrew@wastenaut.ai):** Miles has full content access. This is correct — Miles is the work agent.
- **Family calendar (drew.joiner@gmail.com):** Miles technically receives full content from the API. The calendar-observer skill strips titles/descriptions before processing. This is a prompt-level privacy enforcement — a known gap documented in security-hardening.md.
- Future improvement: wrapper script that strips content before it reaches the agent workspace.
