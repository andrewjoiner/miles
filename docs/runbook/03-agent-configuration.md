# 03 — Agent Configuration

## Pre-Configuration Checklist
- [ ] Docker container `miles-openclaw` is running
- [ ] Model confirmed as Haiku (NOT Opus)
- [ ] Heartbeat confirmed as disabled
- [ ] .env file has correct API keys with permissions 600

## Agent Identity Files

All agent files live in `~/miles/workspace/` on the VM (mounted as a Docker volume).

| File | Purpose | Editable by Miles? |
|------|---------|-------------------|
| SOUL.md | Identity, personality, boundaries | No (Andrew edits) |
| AGENTS.md | Operational rules, authority levels | No (Andrew edits) |
| USER.md | Work context — company, projects, workstreams | No (Andrew edits, Miles can propose updates) |
| TOOLS.md | Integrations, model routing, budget | No (Andrew edits) |
| HEARTBEAT.md | Standing orders, scheduled tasks | No (Andrew edits) |
| SECURITY.md | Non-negotiable security rules | No (Andrew edits) |
| MEMORY.md | Long-term memory — observations and patterns | Yes (Miles writes) |
| daily/*.md | Daily session logs | Yes (Miles writes) |

## Filling In Templates

Before deploying, replace all `{{PLACEHOLDER}}` values in the template files with actual data.

### USER.md — Work Context
USER.md has observation placeholders that will be filled during the shadow period:
- `{{TYPICAL_WORK_HOURS}}` — leave as placeholder, Miles will observe
- `{{MEETING_PATTERNS}}` — leave as placeholder
- `{{FOCUS_TIME_PATTERNS}}` — leave as placeholder
- `{{FREQUENCY}}` — leave as placeholder
- `{{PIPELINE_REVIEW_CADENCE}}` — leave as placeholder

The static sections (company info, projects, tools) are pre-filled from the Obsidian vault knowledge.

### openclaw.json — Requires Actual Values
- `{{AZURE_AI_FOUNDRY_ENDPOINT}}` — the Azure AI Foundry base URL for Anthropic model routing
- `{{ANDREW_TELEGRAM_USER_ID}}` — your numeric Telegram user ID

## Model Routing via Azure AI Foundry

Configure the Anthropic provider to route through Azure Sponsorship credits (effectively $0 model costs):

In `openclaw.json`, set:
```json
"providers": {
  "anthropic": {
    "baseUrl": "https://your-azure-ai-foundry-endpoint.openai.azure.com"
  }
}
```

**Important:** The base URL goes in `openclaw.json` under `models.providers.anthropic.baseUrl`. Environment variables in `.bashrc` do NOT work for OpenClaw. This was a hard-won lesson from Open_Claw_v0.

## Budget Caps

Set in `openclaw.json`:
```json
"budget": {
  "monthlyLimitUsd": 25,
  "alertThresholdPercent": 80
}
```

If using Azure AI Foundry, actual API costs are $0 (covered by Sponsorship credits). The budget cap is a safety net in case the provider config breaks and falls back to direct Anthropic API.

## Verify Configuration

```bash
# Check all workspace files are present
ssh miles-vm "ls -la ~/miles/workspace/"

# Check skills are installed
ssh miles-vm "ls -la ~/miles/workspace/skills/"

# Check MEMORY.md is initialized
ssh miles-vm "cat ~/miles/workspace/MEMORY.md"

# Verify model one more time
ssh miles-vm "docker exec miles-openclaw openclaw status"
```

## Do NOT Test Yet
Agent configuration is complete, but do NOT send test messages until:
1. Telegram is configured (Step 04)
2. Google Calendar OAuth is set up (Step 05)

Without these integrations, Miles has no way to receive messages or read calendars.
