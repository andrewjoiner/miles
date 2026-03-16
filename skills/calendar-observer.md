# Skill — Calendar Observer

## Purpose
Read Google Calendar to observe Andrew's meeting patterns, focus time availability, and schedule density. Cross-reference with pipeline data for future pre-meeting research (V2).

## When to Run
- During the daily observation cycle (7:30 AM ET), after vault-observer and pipeline-observer
- On-demand when Andrew asks about his schedule or availability

## Data Source
- **GoG CLI** (Google Calendar via OAuth2)
- Accounts: `andrew@wastenaut.ai` (full access), `drew.joiner@gmail.com` (opaque blocks only)

## Procedure

### Step 1 — Read Work Calendar
```bash
gog calendar list --from $(date +%Y-%m-%d) --to $(date -d '+1 day' +%Y-%m-%d) --plain
```
For each event on the work calendar (`andrew@wastenaut.ai`), note:
- Event title
- Start and end time
- Duration
- Whether it involves an external contact (meeting vs. internal focus block)

### Step 2 — Read Family Calendar (Opaque Only)
```bash
gog calendar list --account drew.joiner@gmail.com --from $(date +%Y-%m-%d) --to $(date -d '+1 day' +%Y-%m-%d) --plain
```
**PRIVACY RULE:** Strip all event content. Record ONLY as:
- "Personal Conflict [start-end]"
Do NOT store titles, descriptions, locations, or attendees.

### Step 3 — Calculate Today's Schedule Profile
From both calendars, determine:
- **Total meeting hours** (work calendar events)
- **Total blocked hours** (work + personal conflicts)
- **Available focus time** (gaps between blocks)
- **Meeting density:** light (<2 hrs), moderate (2-4 hrs), heavy (>4 hrs)

### Step 4 — Cross-Reference Pipeline (Preparation for V2)
If any work calendar meetings involve contacts that appear in Apollo pipeline data:
- Note the connection: "2:00 PM meeting with Jane Smith — RecycleCo (Proposal stage)"
- In V2, this will trigger a pre-meeting research brief. In V1, just note it in memory.

### Step 5 — Look Ahead (Tomorrow)
Repeat Steps 1-3 for tomorrow's date. Note any particularly heavy or light days for pattern tracking.

## Output
Pass observations to memory-writer. Format:
```
[CALENDAR] Today: 3 meetings (2.5 hrs), 1 personal conflict (1.5 hrs). Focus time: 4 hrs available.
[CALENDAR] Meeting density: moderate. Largest focus block: 9:00-11:30 AM.
[CALENDAR] Pipeline overlap: 2:00 PM with Jane Smith (RecycleCo, Proposal stage)
[CALENDAR] Tomorrow: 1 meeting (30 min). Light day — good for deep work.
```

## What NOT to Do
- NEVER include family calendar titles, descriptions, or details in any output or memory.
- Do not read more than 2 days ahead (today + tomorrow). Weekly view is a V2 capability.
- Do not propose schedule changes in V1. Observation only.
- Do not create or modify calendar events in V1 (even though GoG CLI supports writes).
- Do not store attendee email addresses in memory — reference by name only.

## Error Handling
- If GoG CLI fails (OAuth expired, network issue), skip calendar observation for today.
- Log the error: `[CALENDAR] GoG CLI error: {error_message}. Skipped.`
- If family calendar read fails, proceed with work calendar only.
