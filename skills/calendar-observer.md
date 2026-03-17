# Skill — Calendar Observer

## Purpose
Observe Andrew's meeting patterns, focus time availability, and schedule density. Cross-reference with pipeline data for future pre-meeting research (V2).

**Note:** The `gog` ClawHub skill provides Google Calendar access via GoG CLI. This skill defines *what to observe* and the privacy rules — use the gog skill's commands for calendar reads.

## When to Run
- During the daily observation cycle (7:30 AM ET), after vault-observer and pipeline-observer
- On-demand when Andrew asks about his schedule or availability

## Accounts
- `andrew@wastenaut.ai` — **full access** (work calendar, Miles's primary domain)
- `drew.joiner@gmail.com` — **opaque blocks only** (family calendar, privacy enforced)

## Procedure

### Step 1 — Read Work Calendar
Use the gog skill to list today's events for `andrew@wastenaut.ai`. For each event, note:
- Event title
- Start and end time
- Duration
- Whether it involves an external contact (meeting vs. internal focus block)

### Step 2 — Read Family Calendar (Opaque Only)

**PRIVACY RULE — NON-NEGOTIABLE:**
When reading `drew.joiner@gmail.com` calendar, strip ALL event content. Record ONLY as:
- "Personal Conflict [start-end]"

Do NOT store titles, descriptions, locations, or attendees from this calendar. Ever.

### Step 3 — Calculate Today's Schedule Profile
From both calendars, determine:
- **Total meeting hours** (work calendar events)
- **Total blocked hours** (work + personal conflicts)
- **Available focus time** (gaps between blocks)
- **Meeting density:** light (<2 hrs), moderate (2-4 hrs), heavy (>4 hrs)

### Step 4 — Cross-Reference Pipeline (V2 Preparation)
If any work calendar meetings involve contacts that appear in Apollo pipeline data:
- Note the connection: "2:00 PM meeting with Jane Smith — RecycleCo (Proposal stage)"
- In V2, this triggers a pre-meeting research brief. In V1, just note it.

### Step 5 — Look Ahead (Tomorrow)
Repeat Steps 1-3 for tomorrow's date. Note particularly heavy or light days for pattern tracking.

## Output
Pass tagged observations to the daily observation consolidator:
```
[CALENDAR] Today: 3 meetings (2.5 hrs), 1 personal conflict (1.5 hrs). Focus time: 4 hrs available.
[CALENDAR] Meeting density: moderate. Largest focus block: 9:00-11:30 AM.
[CALENDAR] Pipeline overlap: 2:00 PM with Jane Smith (RecycleCo, Proposal stage)
[CALENDAR] Tomorrow: 1 meeting (30 min). Light day — good for deep work.
```

## What NOT to Do
- **NEVER** include family calendar titles, descriptions, or details in any output or memory.
- Do not read more than 2 days ahead (today + tomorrow). Weekly view is a V2 capability.
- Do not propose schedule changes in V1. Observation only.
- Do not create or modify calendar events in V1 (even though gog supports writes).
- Do not store attendee email addresses in memory — reference by name only.

## Error Handling
- If gog CLI fails (OAuth expired, network issue), skip calendar observation for today.
- Log the error: `[CALENDAR] GoG CLI error: {error_message}. Skipped.`
- If family calendar read fails, proceed with work calendar only.
