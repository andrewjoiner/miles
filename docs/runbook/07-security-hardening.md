# 07 — Security Hardening

## VM Security

### SSH
- Key-based authentication only — password auth disabled
- NSG restricts SSH to Andrew's current IP
- Update NSG each session if IP changes:
```bash
NSG_NAME=$(az network nsg list -g rg-openclaw-eastus --query "[?contains(name, 'miles')].name" -o tsv)
az network nsg rule update \
  --resource-group rg-openclaw-eastus \
  --nsg-name $NSG_NAME \
  --name default-allow-ssh \
  --source-address-prefixes "$(curl -s ifconfig.me)/32"
```

### Network
- No inbound ports open beyond SSH (22)
- OpenClaw gateway binds to localhost only inside the container
- Telegram uses long-polling (outbound only — no webhook, no inbound port required)
- No web-facing services

## Docker Security

### Container Configuration
- Runs as non-root user inside container
- `no-new-privileges` security option enabled
- Restart policy: `unless-stopped`
- tmpfs for /tmp (100MB limit)
- No ports exposed to host network

### File Permissions
```bash
# Verify critical file permissions
ssh miles-vm "ls -la ~/miles/.env"                    # Should be 600
ssh miles-vm "ls -la ~/miles/openclaw.json"           # Should be 600

# Fix if needed
ssh miles-vm "chmod 600 ~/miles/.env ~/miles/openclaw.json"
```

## Credential Security

### Credential Locations
| Credential | Location | Purpose |
|------------|----------|---------|
| Anthropic API key | `~/miles/.env` (ANTHROPIC_API_KEY) | Claude model access (via Azure AI Foundry) |
| Telegram bot token | `~/miles/.env` (TELEGRAM_BOT_TOKEN) | Telegram messaging |
| Apollo API key | `~/miles/.env` (APOLLO_API_KEY) | Pipeline data read |
| Todoist API token | `~/miles/.env` (TODOIST_API_TOKEN) | Task data read |
| GoG keyring password | `~/miles/.env` + `~/.openclaw/.gog_keyring_pw` | Google Calendar keyring unlock |
| GoG default account | `~/miles/.env` (GOG_ACCOUNT) | Default Google account |
| Google OAuth client | `~/.openclaw/client_secret.json` | OAuth2 client credentials |
| Google OAuth tokens | `~/.config/gog/` (managed by GoG CLI) | Per-account refresh tokens |
| Vault deploy key | `~/.ssh/vault_deploy_key` | GitHub vault repo access |
| Telegram allow list | Container internal config | Paired user IDs |

### Systemd Environment Override
GoG environment variables are injected via systemd drop-in config:
```
~/.config/systemd/user/openclaw-gateway.service.d/env.conf
```
This file must also be permission-restricted:
```bash
ssh miles-vm "chmod 600 ~/.config/systemd/user/openclaw-gateway.service.d/env.conf"
```

### What Should NEVER Be in Agent Workspace
- API keys or tokens (these live in `.env` and config files, not in SOUL.md/TOOLS.md/MEMORY.md)
- SSH keys
- OAuth client secrets
- Keyring passwords

## Privacy Enforcement

### Family Calendar
- Miles receives family calendar data via GoG CLI with full content
- **Prompt-level enforcement:** calendar-observer skill strips titles/descriptions, reports only "Personal Conflict [time]"
- **Known gap:** This is prompt-level only. A future integration-layer wrapper should strip content before it reaches the agent
- Periodically verify Miles is not leaking family calendar content:
  - Ask Miles about today's schedule via Telegram
  - Verify personal events appear ONLY as "Personal Conflict [time]"
  - If titles appear, escalate: update skills and clear session

### Personal Vault
- Miles has NO access to the Personal Vault (Ava's domain)
- The Personal Vault is not mounted as a Docker volume
- If Miles references personal/family data, that's a bug — check SOUL.md boundaries

### Work Vault Write Isolation
- Miles reads the full Work Vault
- V1: No writes to vault
- V2+: Writes ONLY to `Miles Outputs/` subfolder — enforced by vault-sync.service commit scope
- If Miles writes outside `Miles Outputs/`, the vault-sync service will not commit those changes

## Telegram Security

### DM Policy
- Only Andrew's Telegram account is allowed (user ID configured in openclaw.json)
- Unknown senders are silently ignored
- V1: Miles responds only when Andrew messages. No unsolicited outbound.

### Token Security
- Bot token stored in .env (permissions 600)
- If token is compromised: revoke via @BotFather, generate new, update .env, restart container
- Bot uses long-polling (not webhook) — no public URL to discover or attack

## Budget Protection

### Azure Level
- Budget alert configured in Azure Portal for the resource group
- Alert at 80% and 100% of monthly VM cost

### API Level
- Monthly budget cap in openclaw.json: $25
- Alert at 80% ($20)
- Azure AI Foundry routes through Azure Sponsorship credits = effectively $0
- The cap protects against fallback to direct Anthropic API

### Heartbeat Cost Control
- Heartbeat uses Haiku model only (cheapest)
- Heartbeat is **DISABLED by default** — only enable after all data sources are confirmed working
- V1: once daily only (7:30 AM ET). No 30-minute routine.
- Monitor API usage: check Azure AI Foundry metrics weekly

## Monitoring Checklist (Weekly)

- [ ] Container running: `ssh miles-vm "docker ps | grep miles-openclaw"`
- [ ] Credential permissions: verify all sensitive files are 600
- [ ] Disk usage: `ssh miles-vm "df -h"` (should be < 80%)
- [ ] Container logs clean: `ssh miles-vm "docker logs miles-openclaw --tail 50"`
- [ ] API spend within budget: check Azure AI Foundry metrics
- [ ] NSG rule current: verify SSH source IP matches your current IP
- [ ] Telegram pairing: verify only Andrew's user ID is in allowedUsers
- [ ] Family calendar privacy: ask Miles about schedule, verify "Personal Conflict" format
- [ ] GoG OAuth tokens valid: test calendar list command (should not 401)
- [ ] Vault sync working: `ssh miles-vm "cd /home/openclaw/work-vault && git log --oneline -3"` (should show recent syncs)
- [ ] MEMORY.md growing: `ssh miles-vm "wc -l ~/miles/workspace/MEMORY.md"` (should increase daily)

## Incident Response

If a security issue is detected:

1. **Stop the container immediately:**
   ```bash
   ssh miles-vm "cd ~/miles && docker compose stop"
   ```
2. **Assess scope:** Determine which credentials may be compromised
3. **Rotate affected credentials:**
   - Telegram token: revoke via @BotFather, generate new, update .env
   - Apollo key: rotate in Apollo settings, update .env
   - Todoist token: regenerate in Todoist settings, update .env
   - Google OAuth: revoke at https://myaccount.google.com/permissions, re-authorize via GoG CLI
   - Anthropic/Azure key: rotate in Azure AI Foundry, update .env
4. **Review logs:**
   ```bash
   ssh miles-vm "docker logs miles-openclaw --since '24 hours ago'"
   ```
5. **Check MEMORY.md and daily logs** for any leaked content (family calendar titles, credentials)
6. **Re-enable** after root cause is identified and fixed

## Known Security Gaps

| Gap | Risk | Mitigation | Fix Timeline |
|-----|------|------------|--------------|
| Family calendar privacy is prompt-level only | Miles could leak family event titles if skills are bypassed | Skill rules + periodic manual verification | V2 — integration-layer wrapper script |
| OAuth app in "Testing" mode | Tokens expire after 7 days | Re-auth when needed; publish app when stable | After shadow period |
| OpenClaw CLI SIGTERMs the gateway | Running CLI commands disrupts bot availability | Avoid CLI commands during active use | Upstream OpenClaw issue |
