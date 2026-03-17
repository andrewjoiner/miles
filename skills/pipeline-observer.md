# Skill — Pipeline Observer

## Purpose
Track deal pipeline movements, contact changes, and enrichment patterns via Apollo API. Supplement the vault snapshot with granular deal details.

## When to Run
- During the daily observation cycle (7:30 AM ET), after vault-observer
- On-demand when Andrew asks about a specific deal or the pipeline

## Data Source
- **Apollo API** (read-only via API key in .env)
- Cross-reference: previous observations for yesterday's pipeline state

## Procedure

### Step 1 — Get Active Opportunities
Query the Apollo API for active opportunities. For each, note:
- Deal name and company
- Current stage
- Amount (if available)
- Last activity date
- Primary contact

### Step 2 — Compare Against Yesterday
Read yesterday's pipeline observations. Identify:
- **New deals:** Opportunities that didn't exist yesterday
- **Stage changes:** Deals that moved forward or backward
- **Stale deals:** Deals with no activity for >7 days
- **Closed deals:** Deals that moved to won or lost since yesterday

### Step 3 — Get Recent Contacts
Query for recently created contacts (last 24 hours). Note new additions.

### Step 4 — Enrichment Check
For deals flagged in the vault snapshot as "needing attention," check enrichment data:
- Contact email status (verified/unverified)
- Company details (industry, size, location)
- Last enrichment date

## Output
Pass tagged observations to the daily observation consolidator:
```
[PIPELINE] 3 active opportunities ($45K total): Acme Corp (Demo), RecycleCo (Proposal), WastePro (Negotiation)
[PIPELINE] Stage change: RecycleCo moved from Demo → Proposal (was Demo for 5 days)
[PIPELINE] Stale: WastePro — no activity for 12 days, last contact was email on 2026-03-04
[PIPELINE] New contact: Jane Smith (VP Operations, GreenWaste Inc) — added today
```

## What NOT to Do
- Do not write raw API responses to memory. Summarize.
- Do not call the Apollo API more than once per daily cycle (rate limits + cost).
- Do not make any write calls to Apollo. V1 is read-only.
- Do not store contact email addresses or phone numbers — reference by name and company only.
- Do not alert Andrew about pipeline changes in V1. Log to memory only.

## Error Handling
- If Apollo API returns an error (401, 429, 500), skip this skill for today's cycle.
- Log the error: `[PIPELINE] Apollo API error: {status_code}. Skipped.`
- Do not retry more than once.
