# Miles Agent — Chief of Staff / Executive Assistant Agent

## Project Overview
Miles is a chief of staff / executive assistant AI agent built on OpenClaw for Andrew's professional operations at Wastenaut. He manages work calendar awareness, pipeline context, task priorities, content tracking, and eventually email coordination, CRM operations, and autonomous scheduling. Miles runs on an Azure VM (OpenClaw native install via systemd), communicates via Telegram, and uses the Obsidian Work Vault as his primary knowledge base.

**Owner:** Andrew Joiner (solo founder, Wastenaut)
**Framework doc:** `reference/miles_ava_framework.docx` (shared with Ava)
**Design doc:** `docs/design-doc.md` (full architecture, phasing, data sources)
**Related agents:** Ava_Agent (household/family), Open_Claw_v0 (Surveyor — research)

## Status
**Phase:** V1 Build — VM provisioned, config templates and skills written. Next: Docker/OpenClaw install, Telegram bot, integrations.

## Azure VM Details
- **Resource Group:** rg-openclaw-eastus
- **VM Name:** vm-miles-01
- **Public IP:** 20.124.189.164
- **Private IP:** 10.0.0.6
- **Size:** Standard_B2ms (2 vCPU, 8GB RAM)
- **OS:** Ubuntu 24.04 LTS
- **SSH Config:** Host alias `miles-vm`
- **NSG:** vm-miles-01NSG (SSH restricted to Andrew's IP)
- **Provisioned:** 2026-03-16
- **Telegram Bot:** @miles_chief_bot
- **Git Remote:** https://github.com/andrewjoiner/miles.git

## Knowledge Dependencies
Before starting work, read these for current context:
- `~/Desktop/Vault/2. Areas/_Company Overview.md` — Company context
- `reference/miles_ava_framework.docx` — Full agent framework (Miles & Ava spec)
- `docs/design-doc.md` — Architecture decisions, phasing, data sources

## Privacy Model
Miles operates in the **work/professional domain only**. He has NO access to family/personal tools.

| Domain | Miles's Access |
|--------|---------------|
| Andrew's work Google Calendar | Full read + write |
| Family Google Calendars | Opaque blocks only |
| Obsidian Work Vault | Full read, write to Miles Outputs/ only |
| Personal Vault | NO access (Ava's domain) |
| Apollo | Read (phased) |
| Todoist | Read (phased) |
| HubSpot | Read (V2), Write (V3) |
| Gmail | Read (V2), Draft (V3), Send (V4) |
| Skylight | NO access (Ava's domain) |
| Telegram | Read + write (separate bot from Ava) |

## Architecture — Two-Layer Data Model
- **Layer 1 (Vault):** Obsidian Work Vault git-synced to VM. Daily snapshots from Cowork's daily-scan provide the activity index (what changed, where to look).
- **Layer 2 (APIs):** Direct API reads (Apollo, Todoist, Google Calendar) provide granular detail that the vault summarizes but doesn't contain.

The vault snapshot is the **index**. The APIs are the **lookup**. Miles follows up on snapshot flags by reading the relevant tool.

## V1 — Shadow Mode
Miles V1 is read-only observation. He reads all data sources daily, detects changes, notes patterns, and writes to MEMORY.md. No output to Andrew unless asked. This is the trust-building phase.

**Duration:** 4-6 weeks
**Output:** MEMORY.md grows with pipeline context, work rhythms, project patterns, deal history.

## Conventions
- Same as Ava: SSH from local, never expose keys, python3, .md.template for templates
- OpenClaw runs natively via systemd (not Docker for V1)
- Costs tracked monthly in Obsidian project note
- Calendar access via GoG CLI (same tool as Ava, separate OAuth)

## Critical Cost Control Rules
Same as Ava — lessons from $40 Opus mistake:
1. Override model to Haiku immediately on install
2. Model format: `anthropic/claude-haiku-4-5`
3. Verify model before first message
4. Keep heartbeat to once daily (not every 30 min)
5. Disable heartbeat until Telegram is configured

## Communication Channel
- **V1:** Telegram (separate bot from Ava)
- **V1 behavior:** Mostly silent. Responds only when Andrew messages directly.
- **V2+:** Daily morning brief via Telegram.

## Model Configuration
- **Primary (observation):** Haiku 4.5 — daily heartbeat, memory writes
- **Reasoning:** Sonnet 4.5 — analysis, summarization, drafting (V2+)
- **Budget cap:** $25/month API spend
- **Provider:** Azure AI Foundry ($0 via Sponsorship credits)

## Project Structure
```
reference/              — Source framework document
config/templates/       — Agent config templates (6 files)
skills/                 — V1 observation skills
docs/                   — Design doc, runbook, handoff doc
docs/architecture/      — Architecture decision records
scripts/                — Deployment and utility scripts
```
