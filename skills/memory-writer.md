# Skill — Daily Observation Consolidator

## Purpose
Consolidate observations from all observer skills into a daily memory entry. This is the final step of each daily observation cycle.

**Note:** The `self-improving` ClawHub skill manages the underlying memory system (tiered HOT/WARM/COLD storage, learning capture, error corrections). This skill defines *what* Miles should record from the daily observation cycle — the self-improving skill handles *how* it's stored and retrieved.

## When to Run
- At the end of each daily observation cycle, after all observers have completed
- When Andrew explicitly says "remember this" during a conversation

## Data Sources
- Observations passed from: vault-observer, pipeline-observer, task-observer, calendar-observer
- Direct instructions from Andrew during conversation

## Procedure

### Step 1 — Gather Observer Outputs
Collect tagged observations from each observer:
- `[VAULT]` — vault snapshot changes, weekly focus alignment
- `[PIPELINE]` — Apollo deal movements, stale deals, new contacts
- `[TASKS]` — completion patterns, overdue items, workstream attention
- `[CALENDAR]` — schedule profile, focus time, pipeline overlaps

### Step 2 — Apply Observation Rules

**Include:**
- Factual observations with specific numbers (deal counts, task counts, meeting hours)
- Changes from yesterday (stage movements, new contacts, completed tasks)
- Cross-source patterns (weekly focus aligns with task completions; meeting with prospect + stale deal)
- Explicit corrections or confirmations from Andrew

**Exclude:**
- Raw data dumps (API responses, full task lists)
- Guesses or inferences not supported by data
- Personal/family information (even if accidentally seen)
- Credential values or API keys
- Duplicate information already in yesterday's entry (note "unchanged" instead)

### Step 3 — Write Daily Entry
Use the self-improving skill's memory system to record today's observations. Structure the entry as:

- **Pipeline:** Deal count, total value, stage changes, stale alerts, new contacts
- **Tasks:** Active count, overdue count, completions today, neglected workstreams
- **Calendar:** Meeting hours, focus time available, density rating, pipeline overlaps
- **Vault:** Snapshot deltas, weekly focus alignment, staleness warnings
- **Patterns:** Cross-cutting observations across data sources

Keep each observation to one line. Be specific and quantitative:
- Good: "3 active deals, $45K total. RecycleCo moved Demo→Proposal."
- Bad: "Pipeline looks healthy with some activity."

Do not write more than 20 lines per daily entry.

### Step 4 — Pattern Detection (Weekly)
On Fridays (or the last observation day of the week), add a weekly patterns summary:
- Key movements for the week
- Emerging trends (e.g., "Andrew consistently completes Stream API tasks but Terminal tasks stall")
- Anomalies (e.g., "No Apollo activity all week despite 2 active opportunities")

The self-improving skill will automatically manage memory tiering — recent patterns stay HOT, confirmed patterns move to WARM, historical context moves to COLD.

## What NOT to Do
- Do not duplicate the self-improving skill's memory management. Let it handle storage, retrieval, and tiering.
- Do not write observations you're not confident about. If data is missing (API failed), note the gap rather than guessing.
- Do not write personal/family information.
- Do not write Andrew's opinions or feelings — only factual observations.
- Do not store raw API responses or full task lists.

## Error Handling
- If any observer failed during the cycle, note the gap: "Pipeline: skipped (Apollo API error)"
- Never lose observations — if memory write fails, log them in the daily log as a fallback.
