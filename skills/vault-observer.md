# Skill — Vault Observer

## Purpose
Read the Work Vault's daily snapshot and weekly planning docs to identify notable changes across Andrew's projects, pipeline, and tools.

## When to Run
- During the daily observation cycle (7:30 AM ET)
- On-demand when Andrew asks about recent changes or project status

## Data Sources
- **Daily Snapshots:** `/home/openclaw/work-vault/0. Dashboard/Daily Snapshots/YYYY-MM/`
- **Weekly Planning:** `/home/openclaw/work-vault/0. Dashboard/Weekly/`
- **Project Notes:** `/home/openclaw/work-vault/1. Projects/`
- **Strategy Docs:** `/home/openclaw/work-vault/2. Areas/`

## Procedure

### Step 1 — Find Today's Snapshot
Look for today's date in `0. Dashboard/Daily Snapshots/` (format: `YYYY-MM/YYYY-MM-DD.md`).
If today's snapshot doesn't exist yet (Cowork daily-scan runs at 7:00 AM, Miles runs at 7:30 AM), check yesterday's snapshot instead. Note which date you're reading.

### Step 2 — Extract Key Sections
From the daily snapshot, extract:
- **Apollo pipeline state:** Number of active opportunities, any deals needing attention, new contacts
- **Instantly inbound:** Any replies flagged as "action required"
- **Git activity:** Repos with recent commits, dirty repos, staleness warnings
- **File changes:** Which project directories had file modifications
- **Todoist completions:** Tasks completed since last snapshot
- **Staleness warnings:** Repos or projects with no activity for extended periods

### Step 3 — Compare Against Yesterday
Read yesterday's snapshot (or last available) and identify deltas:
- New deals or contacts that didn't exist yesterday
- Deals that changed stage
- Projects that went from active to stale (or vice versa)
- Unusual patterns (e.g., burst of activity in a normally quiet project)

### Step 4 — Check Weekly Focus
Read the current week's planning doc from `0. Dashboard/Weekly/`. Note:
- This week's focus areas
- Priority tasks for the week
- Any blockers mentioned

Cross-reference with the daily snapshot: is Andrew's actual activity aligned with the weekly plan?

### Step 5 — Drill Into Flagged Projects
If a project is flagged in the snapshot (staleness warning, unusual activity, mentioned in weekly focus), read the project note from `1. Projects/[ProjectName].md` for additional context.

Do NOT read every project note every day. Only drill in when something is flagged.

## Output
Pass all extracted observations to the **memory-writer** skill for consolidation into MEMORY.md.

Format observations as:
```
[VAULT] Apollo: 3 active opportunities (unchanged from yesterday)
[VAULT] Instantly: 1 inbound reply flagged for action (new)
[VAULT] Git: Stream API had 4 commits; Database-Completion stale 12 days
[VAULT] Weekly focus: Stream API launch + outbound campaign (aligned with activity)
```

## What NOT to Do
- Do not read the entire vault every day. Use the snapshot as an index.
- Do not summarize strategy docs unless specifically asked by Andrew.
- Do not compare across weeks unless asked — focus on day-over-day changes.
- Do not store raw snapshot content in memory — summarize observations only.
