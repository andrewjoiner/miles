# 00 — Prerequisites

Complete these before starting any deployment steps.

## Azure
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Subscription confirmed: Microsoft Azure Sponsorship
- [ ] Resource group `rg-openclaw-eastus` exists (shared with Ava and Surveyor VMs)

## SSH
- [ ] SSH key available at `~/.ssh/id_rsa` (RSA — same key used for Ava and Surveyor VMs)
- [ ] Know your current public IP for NSG rules (`curl ifconfig.me`)

## Telegram
- [ ] Telegram account (Andrew's personal account)
- [ ] Bot created via @BotFather:
  1. Open Telegram, search for @BotFather
  2. Send `/newbot`
  3. Name: `Miles` (or `Miles Chief`)
  4. Username: `miles_chief_bot` (must be unique, end in `bot`)
  5. Save the bot token — this becomes `TELEGRAM_BOT_TOKEN` in .env
- [ ] Get your Telegram user ID (send a message to @userinfobot) — this goes in `openclaw.json` allowedUsers
- [ ] Send a test message to your new bot (it won't reply yet, but this initializes the chat)

## Google Calendar
- [ ] Google Cloud Console access (console.cloud.google.com)
- [ ] Google Cloud project with Calendar API enabled (can reuse the project from Ava setup)
- [ ] OAuth2 client credentials downloaded (`client_secret.json`)
- [ ] Calendar IDs identified:
  - `andrew@wastenaut.ai` (work calendar — full access)
  - `drew.joiner@gmail.com` (family calendar — opaque blocks only)

## Apollo API
- [ ] Apollo account with API access
- [ ] API key available (check existing Cowork integration for the key)
- [ ] Confirm read-only scopes are sufficient for opportunities + contacts endpoints

## Todoist API
- [ ] Todoist account
- [ ] Personal API token available (Settings → Integrations → Developer → API token)
- [ ] Confirm token provides read access to tasks and activity

## Work Vault
- [ ] Work Vault (`~/Desktop/Vault/`) has GitHub remote configured
  - Verify: `cd ~/Desktop/Vault && git remote -v`
  - Expected: `origin https://github.com/andrewjoiner/vault.git`
- [ ] GitHub deploy key will be generated on the VM during vault sync setup

## Local Tools
- [ ] Docker CLI basics understood (docker run, docker compose, docker logs)
- [ ] `scp` available for file transfer to VM
- [ ] GoG CLI familiar from Ava setup (same tool, separate OAuth authorization)
