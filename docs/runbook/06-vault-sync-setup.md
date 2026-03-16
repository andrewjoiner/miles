# 06 — Work Vault Sync Setup

## Overview
The Work Vault (`~/Desktop/Vault/` on Andrew's Mac) is git-synced to the VM so Miles can read daily snapshots, project notes, and strategy docs. Same pattern as Ava's Personal Vault sync.

## Generate Deploy Key on VM

```bash
ssh miles-vm

# Generate a deploy key (no passphrase — systemd timer needs unattended access)
ssh-keygen -t ed25519 -C "miles-vm-vault-deploy" -f ~/.ssh/vault_deploy_key -N ""

# Show the public key (you'll add this to GitHub)
cat ~/.ssh/vault_deploy_key.pub
```

## Add Deploy Key to GitHub

1. Go to https://github.com/andrewjoiner/vault/settings/keys
2. Click "Add deploy key"
3. Title: `miles-vm-vault-deploy`
4. Key: paste the public key from above
5. Check "Allow write access" (Miles needs to push `Miles Outputs/` changes in V2+)
6. Click "Add key"

## Configure SSH for GitHub

```bash
ssh miles-vm

cat >> ~/.ssh/config << 'EOF'
Host github.com-vault
    HostName github.com
    User git
    IdentityFile ~/.ssh/vault_deploy_key
    IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config
```

## Clone the Work Vault

```bash
ssh miles-vm

# Clone using the deploy key alias
git clone git@github.com-vault:andrewjoiner/vault.git /home/openclaw/work-vault

# Verify
ls /home/openclaw/work-vault/
```

You should see the vault structure: `0. Dashboard/`, `1. Projects/`, `2. Areas/`, etc.

## Configure Git Identity

```bash
ssh miles-vm
cd /home/openclaw/work-vault
git config user.name "Miles Agent"
git config user.email "miles@wastenaut.ai"
```

## Install Systemd Sync Units

Copy the vault-sync service and timer from the local project:

```bash
# From local machine:
scp scripts/vault-sync.service miles-vm:~/.config/systemd/user/vault-sync.service
scp scripts/vault-sync.timer miles-vm:~/.config/systemd/user/vault-sync.timer
```

Or create them directly on the VM:

```bash
ssh miles-vm

mkdir -p ~/.config/systemd/user

# Service
cat > ~/.config/systemd/user/vault-sync.service << 'EOF'
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
EOF

# Timer (every 10 minutes)
cat > ~/.config/systemd/user/vault-sync.timer << 'EOF'
[Unit]
Description=Work Vault sync timer (every 10 minutes)

[Timer]
OnBootSec=2min
OnUnitActiveSec=10min
Persistent=true

[Install]
WantedBy=timers.target
EOF
```

## Enable and Start

```bash
ssh miles-vm

# Enable lingering so timers persist after SSH logout
sudo loginctl enable-linger openclaw

# Reload systemd
systemctl --user daemon-reload

# Enable and start the timer
systemctl --user enable vault-sync.timer
systemctl --user start vault-sync.timer

# Verify timer is active
systemctl --user status vault-sync.timer
systemctl --user list-timers
```

## Test Manual Sync

```bash
ssh miles-vm

# Run the sync manually
systemctl --user start vault-sync.service

# Check the result
systemctl --user status vault-sync.service

# Verify vault is up to date
cd /home/openclaw/work-vault && git log --oneline -3
```

## Create Miles Outputs Directory

```bash
ssh miles-vm
mkdir -p /home/openclaw/work-vault/"Miles Outputs"
```

This directory will be used in V2+ when Miles writes summaries, briefs, and reports to the vault.

## Verify From OpenClaw

After starting the OpenClaw container, verify Miles can read the vault:
```bash
ssh miles-vm "docker exec miles-openclaw ls /home/openclaw/work-vault/"
```

Note: The work-vault directory may need to be mounted as an additional Docker volume. Update `docker-compose.yml` if needed:
```yaml
volumes:
  - ./workspace:/home/openclaw/.openclaw/workspace
  - ./openclaw.json:/home/openclaw/.openclaw/openclaw.json:ro
  - /home/openclaw/work-vault:/home/openclaw/work-vault:ro
```

## Troubleshooting
- **git pull fails:** Check deploy key permissions and GitHub access
- **Timer not firing:** Check `systemctl --user list-timers` and `journalctl --user -u vault-sync`
- **Merge conflicts:** The sync only commits to `Miles Outputs/` — conflicts should be rare. If they occur, the `--autostash` flag handles uncommitted changes.
