# Skill — Memory Writer

## Purpose
Consolidate observations from all observer skills into MEMORY.md. This is the final step of each daily observation cycle. MEMORY.md is Miles's long-term knowledge store.

## When to Run
- At the end of each daily observation cycle, after all observers have completed
- When Andrew explicitly says "remember this" during a conversation

## Data Sources
- Observations passed from: vault-observer, pipeline-observer, task-observer, calendar-observer
- Direct instructions from Andrew during conversation

## Procedure

### Step 1 — Read Current Memory
Read MEMORY.md to understand what's already stored. Note:
- The most recent entry date
- Existing patterns and observations
- Any corrections Andrew has made

### Step 2 — Prepare Today's Entry
Create a new dated section at the top of MEMORY.md:

```markdown
## YYYY-MM-DD

### Pipeline
- [observations from pipeline-observer]

### Tasks
- [observations from task-observer]

### Calendar
- [observations from calendar-observer]

### Vault
- [observations from vault-observer]

### Patterns
- [any cross-cutting patterns noticed across data sources]
```

### Step 3 — Apply Observation Rules
Before writing, apply these filters:

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

### Step 4 — Write to MEMORY.md
Prepend today's entry to MEMORY.md (newest entries at top). Do not delete old entries — they form the historical record.

Keep each observation to one line. Be specific and quantitative:
- Good: "3 active deals, $45K total. RecycleCo moved Demo→Proposal."
- Bad: "Pipeline looks healthy with some activity."

### Step 5 — Pattern Detection (Weekly)
On Fridays (or the last observation day of the week), add a "Weekly Patterns" section:
- Summarize the week's key movements
- Note emerging trends (e.g., "Andrew consistently completes Stream API tasks but Terminal tasks stall")
- Flag anomalies (e.g., "No Apollo activity all week despite 2 active opportunities")

## Memory Structure
MEMORY.md should follow this structure:

```markdown
# Memory — Miles

## Weekly Patterns
<!-- Updated each Friday -->

## YYYY-MM-DD (most recent)
### Pipeline
### Tasks
### Calendar
### Vault
### Patterns

## YYYY-MM-DD (previous day)
...
```

## Memory Hygiene
- After 30 days, old daily entries can be summarized into a "Month Summary" section to keep the file manageable.
- Never delete entries less than 30 days old.
- If Andrew corrects an observation, add the correction as a new entry (don't edit the original). This preserves the learning history.
- If MEMORY.md exceeds 500 lines, create a monthly archive: `workspace/memory-archive/YYYY-MM.md`

## What NOT to Do
- Do not write observations you're not confident about. If data is missing (API failed), note the gap rather than guessing.
- Do not write personal/family information.
- Do not write Andrew's opinions or feelings — only factual observations.
- Do not remove or edit previous entries (except for the 30-day summarization).
- Do not write more than 20 lines per daily entry. If there's more to say, you're being too verbose.

## Error Handling
- If MEMORY.md doesn't exist, create it with the header structure.
- If writing fails, log the attempted observations in the daily log as a fallback.
- Never lose observations — if memory write fails, they must be captured somewhere.
