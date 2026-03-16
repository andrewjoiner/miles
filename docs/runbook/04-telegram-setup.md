# 04 — Telegram Setup

## Prerequisites
- [ ] Bot created via @BotFather (`@miles_chief_bot`)
- [ ] Bot token saved
- [ ] Andrew's Telegram user ID obtained (@userinfobot)
- [ ] OpenClaw container running (from Step 02)

## Create the Bot (if not done in prerequisites)

1. Open Telegram, search for @BotFather
2. Send `/newbot`
3. Name: `Miles`
4. Username: `miles_chief_bot`
5. Copy the bot token

## Bot Settings in @BotFather

```
/setdescription — Miles — Chief of Staff agent for Andrew Joiner
/setprivacy — Disable (so the bot can receive forwarded messages)
/setuserpic — (optional, can add later)
```

## Configure OpenClaw Telegram Channel

The Telegram channel is configured in `openclaw.json`:

```json
"channels": {
  "telegram": {
    "enabled": true,
    "botToken": "${TELEGRAM_BOT_TOKEN}",
    "allowedUsers": ["{{ANDREW_TELEGRAM_USER_ID}}"]
  }
}
```

1. Add `TELEGRAM_BOT_TOKEN` to `~/miles/.env`:
```bash
ssh miles-vm "echo 'TELEGRAM_BOT_TOKEN=your-actual-bot-token' >> ~/miles/.env"
```

2. Update `allowedUsers` in `openclaw.json` with your numeric Telegram user ID.

3. Restart the container:
```bash
ssh miles-vm "cd ~/miles && docker compose restart"
```

## Test Message Flow

1. Open Telegram and find @miles_chief_bot
2. Send: `Hello Miles`
3. Check container logs:
```bash
ssh miles-vm "docker logs miles-openclaw --tail 10"
```
4. Miles should respond based on SOUL.md — professionally, briefly

## Test On-Demand Query

Send: `What do you know so far?`
Miles should respond that he's in shadow mode and hasn't accumulated observations yet (MEMORY.md is empty).

## Security Notes
- `allowedUsers` restricts who can message Miles. Only Andrew's user ID should be listed.
- The bot token is a secret — it's in .env (permissions 600). The `${TELEGRAM_BOT_TOKEN}` syntax references the environment variable.
- Unknown senders are silently ignored (no response, no error to attacker).

## Troubleshooting
- **Bot doesn't respond:** Check `docker logs miles-openclaw` for errors. Common issue: bot token incorrect or not in .env.
- **"Unauthorized" in logs:** The bot token may have been revoked. Regenerate in @BotFather.
- **Messages delayed:** Telegram webhook may not be set. OpenClaw typically handles this on startup, but check logs for webhook registration.

## After Telegram is Working
Do NOT enable heartbeat yet. Continue to Step 05 (Google Calendar) and Step 06 (Vault Sync) first. Heartbeat should only be enabled after all data sources are accessible.
