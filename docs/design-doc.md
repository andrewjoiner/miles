# Miles Agent — Design Document

**Created:** 2026-03-16
**Last updated:** 2026-03-16
**Status:** Design phase — not yet built

---

## What Miles Is

Miles is a **chief of staff / executive assistant agent** for Andrew's professional operations at Wastenaut. He manages work calendar awareness, pipeline context, task priorities, content tracking, and eventually email coordination, CRM operations, and autonomous scheduling.

Miles is the third OpenClaw agent (after Surveyor and Ava). He builds on all lessons learned from both.

**Key distinction from Ava:** Ava is household/family. Miles is business/professional. They share only the Google Calendar data bus — each sees the other's events as opaque time blocks.

**Key distinction from Surveyor:** Surveyor is a specialized research agent (tipping fee data collection). Miles is a general-purpose executive operations agent.

---

## Design Philosophy

### Shadow First, Act Later

Miles V1 is an **observation and memory-building agent**. He reads data sources, detects changes, notes patterns, and writes to MEMORY.md — but produces no output to Andrew unless asked. This is the "shadow the boss for a few weeks" phase.

The goal: when Miles eventually graduates to producing morning briefs, drafting emails, or managing pipeline — he already has weeks of accumulated context about Andrew's work rhythms, deal patterns, content cadence, and tool usage.

### Two-Layer Data Architecture

| Layer | Source | What Miles Gets |
|-------|--------|----------------|
| **Narrative + Activity** | Work Vault (git-synced) | What happened, what changed, priorities, strategy context, content output, weekly focus |
| **Granular Data** | Direct API reads (Apollo, Todoist, Google Calendar) | Specific records, deal details, contact info, task deadlines |

The vault's daily snapshot (produced by Cowork's `daily-scan` at 7 AM) is the **index**. It tells Miles where to look. The APIs provide the **detail**. Miles follows up on snapshot flags by reading the relevant tool directly.

Example: Snapshot says "Apollo returned 2 active opportunities." Miles calls Apollo API → gets deal records with contacts, stages, amounts, last touch dates → writes context to MEMORY.md.

### Cowork Graduation Path

Andrew currently uses Claude Cowork for human-in-the-loop automations (Apollo enrichment, Instantly sequence management, HubSpot operations, LinkedIn content, etc.). These automations are already writing to external tools.

Miles's path:
1. **V1 (Shadow):** Observe Cowork's output in the tools. Build memory from the patterns.
2. **V2 (Assist):** When Andrew asks, Miles can answer questions about pipeline, tasks, or patterns — drawing from memory.
3. **V3 (Draft):** Miles starts producing morning briefs, pre-meeting research, email drafts — for approval.
4. **V4 (Take Over):** Proven Cowork automations migrate to Miles as autonomous skills. Cowork handles new/experimental workflows; Miles handles the stable ones.

### ADHD Design Principles (inherited from Ava)

- No unprompted check-ins or productivity nudges
- Task prioritization is opinionated — one clear starting point, not a ranked list
- Pre-meeting briefs are short: who, what stage, last contact, one suggested talking point
- Work journal is a background record — not a dashboard to maintain
- When Miles detects a conflict, one recommended resolution, not three options
- Morning brief is scannable in 30 seconds

---

## Infrastructure

### VM

- **Separate VM** (vm-miles-01) in existing resource group rg-openclaw-eastus
- **Size:** Standard_B2ms (2 vCPU, 8GB RAM) — same as Ava and Surveyor
- **OS:** Ubuntu 24.04 LTS
- **Future:** Containerize all agents on one larger VM with backup

### OpenClaw Instance

- Completely separate from Ava and Surveyor
- Own workspace, credentials, memory, skills
- Same OpenClaw version (2026.3.11 — avoid 2026.3.12 ANTHROPIC_MODEL_ALIASES bug)
- Same Azure AI Foundry provider for model routing ($0 via Sponsorship credits)

### Model Routing

- **Heartbeat/triage:** Haiku 4.5 (background observation, memory writes)
- **Reasoning:** Sonnet 4.5 (when Miles needs to analyze, summarize, or draft)
- **Budget:** $25/month cap (same as Ava). Effectively $0 via Azure AI Foundry.

### Communication

- **Telegram:** Separate bot (distinct from Ava's @ava_support_bot)
- **V1:** Miles is mostly silent. Responds only when Andrew messages him directly.
- **V2+:** Morning brief via Telegram. On-demand Q&A about pipeline, tasks, schedule.

---

## Data Sources

### Work Vault (Primary — always available)

The Obsidian Work Vault (`~/Desktop/Vault/`) is git-synced and contains:

**Daily Snapshots** (`0. Dashboard/Daily Snapshots/YYYY-MM/`) — produced by Cowork daily-scan at 7 AM:
- Apollo deal pipeline state (active deals, deals needing attention)
- Instantly inbound replies (action required flags)
- Git activity across all repos (commits, dirty repos, staleness warnings)
- File changes across all project directories
- Vault modifications
- Todoist completions
- Staleness warnings for neglected repos

**Weekly Planning** (`0. Dashboard/Weekly/`):
- Focus areas for the week
- Project tasks and priorities
- Wins, blockers, next week preview

**Project Notes** (`1. Projects/`):
- 25 project files with status, sprint tasks, blockers
- Each project maps to a workstream (product, GTM, data, maintenance)

**Strategy & Knowledge** (`2. Areas/`):
- Company Overview, Product notes (Nexus, Stream API, Terminal)
- Positioning, Brand Voice, GTM Priorities
- Deal Pipeline model, Sales MOC, GTM Operations
- Data Capabilities, Platform Architecture

**Content** (`2. Areas/Marketing/LinkedIn Content/`):
- Published posts (full text)
- Content briefs, content calendar, content pillars

**Cowork Outputs** (`CLAUDE OUTPUTS/`):
- System designs (RevOps reorganization, HubSpot migration, etc.)
- Skills and automation designs

**What the vault does NOT capture:**
- Granular Apollo/HubSpot records (contact details, deal amounts, activity logs)
- Todoist task list with deadlines (only completions show up in snapshot)
- Instantly sequence metrics (open rates, reply rates)
- Gmail email threads
- Real-time calendar state

### Google Calendar (andrew@wastenaut.ai)

- Full read/write access (not opaque — Miles is the work agent)
- GoG CLI (OAuth2) — same tool as Ava, separate authorization on Miles's VM
- Shows meetings, focus blocks, travel, deadlines
- Privacy: Ava sees this calendar as opaque blocks. Miles sees full content.

### Apollo API (Read-only V1)

- Contact records, deal stages, enrichment data
- Pipeline state (what the daily snapshot summarizes)
- Follows up on snapshot flags: "2 active opportunities" → get full details

### Todoist API (Read-only V1)

- Full task list with deadlines, priorities, project assignments
- Completion history (supplements vault snapshot)
- Patterns: which projects get tasks done, which stall

### Future Integrations (V2+)

| Integration | Phase | Purpose |
|-------------|-------|---------|
| HubSpot API | V2 | CRM records, activity logging (when Miles starts writing) |
| Instantly API | V2 | Sequence performance, reply management |
| Gmail | V2-V3 | Email triage, draft responses, scheduling coordination |
| GitHub API | V2 | PR reviews, issue tracking, commit patterns |
| Brave Search | V3 | Prospect research, competitive intelligence |

---

## Privacy Firewall

| Data | Miles Sees | Ava Sees |
|------|-----------|----------|
| Work calendar (andrew@wastenaut.ai) | Full content | Opaque blocks ("Work Conflict 2-4pm") |
| Family calendars | Opaque blocks ("Personal Conflict 3:30-5pm") | Full content |
| Work Vault (Obsidian) | Full read + write (Miles Outputs/) | No access |
| Personal Vault | No access | Full read + write (Ava Outputs/) |
| Gmail | Read (phased) | No access |
| HubSpot / Apollo / Todoist | Read (phased) | No access |
| Skylight | No access | Full access |
| Telegram | Separate bot | Separate bot |

No shared credentials, memory, workspace, or skills between agents.

### Inter-Agent Communication (V3+)

Miles and Ava share only the Google Calendar data bus. Neither reads the other's domain content. Future: Ava could ask "Is Andrew free Saturday?" by reading the work calendar's opaque blocks. No direct agent-to-agent messaging in V1-V2.

---

## Versioned Capability Roadmap

### V1 — Shadow Mode (weeks 1-6)

**What Miles does:** Reads everything. Writes only to MEMORY.md. Silent unless asked.

**Daily heartbeat (once per day, Haiku):**
1. Read today's vault snapshot → identify changes worth noting
2. Call Apollo API → get current deal details for any flagged opportunities
3. Call Todoist API → get open tasks, recent completions
4. Read Google Calendar → get today's meetings
5. Compare against yesterday's memory → detect patterns, changes, anomalies
6. Write observations to MEMORY.md

**On-demand (when Andrew messages Miles):**
- "What's the status of [deal]?" → Miles checks memory + Apollo
- "What did I work on this week?" → Miles reads vault snapshots + Todoist
- "Any stale deals?" → Miles checks memory for pipeline patterns

**V1 Skills:**
- `vault-observer.md` — reads vault snapshots, extracts notable changes
- `pipeline-observer.md` — reads Apollo, tracks deal movements
- `task-observer.md` — reads Todoist, tracks completion patterns
- `calendar-observer.md` — reads work calendar, notes meeting patterns
- `memory-writer.md` — consolidates observations into MEMORY.md

**V1 does NOT include:**
- Morning briefs
- Email access
- Writing to any external tool
- Unsolicited messages

### V2 — Morning Brief + Q&A (weeks 6-12)

- Daily morning brief via Telegram (calendar + priorities + pipeline flags)
- Pre-meeting research briefs (on-demand or triggered by confirmed meetings)
- Email triage (Gmail read-only, flag + categorize)
- HubSpot read access for deeper CRM context
- Work journal maintained silently in vault

### V3 — Draft + Write with Approval (weeks 12-24)

- Email draft responses (Andrew approves before sending)
- CRM activity logging (post-meeting notes → HubSpot)
- Calendar conflict resolution proposals
- Stale pipeline alerts and follow-up suggestions

### V4 — Cowork Automation Migration (6+ months)

- Proven Cowork automations move to Miles as autonomous skills
- Miles executes stable workflows; Cowork handles experimental ones
- Act-and-report for routine operations
- Inter-agent calendar coordination with Ava

---

## Project Structure

```
Miles_Agent/
├── CLAUDE.md                        — Project config for Claude Code
├── reference/
│   └── miles_ava_framework.docx     — Source framework document (shared with Ava)
├── config/
│   ├── templates/                   — Agent config templates
│   │   ├── soul.md.template
│   │   ├── agents.md.template
│   │   ├── user.md.template
│   │   ├── tools.md.template
│   │   ├── heartbeat.md.template
│   │   └── security-rules.md.template
│   └── openclaw.json.template
├── skills/                          — V1 observation skills
│   ├── vault-observer.md
│   ├── pipeline-observer.md
│   ├── task-observer.md
│   ├── calendar-observer.md
│   └── memory-writer.md
├── docs/
│   ├── design-doc.md                — This file
│   ├── context-handoff.md           — Session handoff doc (created during build)
│   └── runbook/                     — Deployment runbook (adapted from Ava)
└── scripts/
    └── deploy.sh                    — Deployment script
```

---

## Build Sequence (when ready)

1. **Provision VM** — vm-miles-01, Standard_B2ms, Ubuntu 24.04, same resource group
2. **Install OpenClaw** — NVM + npm, same process as Ava (runbook step 01)
3. **Configure identity** — Deploy SOUL.md, AGENTS.md, USER.md, TOOLS.md, HEARTBEAT.md
4. **Create Telegram bot** — Via @BotFather, pair Andrew
5. **Authorize Google Calendar** — GoG CLI OAuth for andrew@wastenaut.ai (full access)
6. **Sync Work Vault** — GitHub repo + deploy key + systemd timer (same pattern as Ava's Personal Vault)
7. **Configure Apollo API** — Read-only API key in .env
8. **Configure Todoist API** — Read-only token in .env
9. **Deploy V1 skills** — Observer skills + memory writer
10. **Enable heartbeat** — Once daily observation cycle
11. **Shadow period** — 4-6 weeks of silent observation, MEMORY.md grows
12. **V2 decision** — Review memory quality, decide on morning brief activation

---

## Lessons Applied from Ava + Surveyor

| Lesson | How Applied |
|--------|------------|
| Model defaults to Opus ($40 mistake) | Override to Haiku immediately. Verify before first message. |
| Heartbeat costs money | Daily (not every 30 min). Haiku for observation. Sonnet only for reasoning. |
| n8n adds fragility | Direct API calls (Apollo, Todoist, GoG CLI). No middleware for V1. |
| .bashrc env vars don't propagate | Use .env and openclaw.json. Systemd override for GoG vars. |
| CLI commands SIGTERM the gateway | Avoid during active use. |
| Vault as knowledge base works | Work Vault is Miles's primary data source, same pattern as Ava's Personal Vault. |
| Skills as plain-English files | Observer skills are instruction docs, not code. |
| Telegram works fine | Separate bot, same platform as Ava. |
| OpenClaw 2026.3.12 has bug | Stay on 2026.3.11. |
| Agent re-reads config at session start | Clear stale sessions after config changes. |

---

## Cost Model

| Component | Monthly Cost |
|-----------|-------------|
| Azure VM (Standard_B2ms) | ~$81 |
| Anthropic API (via Azure AI Foundry) | ~$0 (Sponsorship credits) |
| Telegram | $0 |
| Apollo API | $0 (existing account) |
| Todoist API | $0 (existing account) |
| **Total** | **~$81/month** |

---

## Open Questions

- [ ] Work Vault GitHub repo — does `~/Desktop/Vault/` already have a GitHub remote? If not, need to set one up (same pattern as ava-vault).
- [ ] Apollo API access — what authentication method? API key or OAuth? Need to check current Cowork integration.
- [ ] Todoist API — personal token or OAuth app? Check how Cowork accesses it.
- [ ] Telegram bot name for Miles — `@miles_chief_bot`? `@miles_cos_bot`? Andrew to decide.
- [ ] Daily snapshot timing — Cowork daily-scan runs at 7 AM. Miles's heartbeat should run after, e.g. 7:30 AM, to ensure the snapshot is fresh.
- [ ] Work Vault write scope — should Miles write to a `Miles Outputs/` folder (like Ava's `Ava Outputs/`), or does he not write to the vault in V1?
