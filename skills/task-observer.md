# Skill — Task Observer

## Purpose
Read Todoist API data to track Andrew's tasks, completion patterns, overdue items, and workstream attention distribution.

## When to Run
- During the daily observation cycle (7:30 AM ET), after vault-observer
- On-demand when Andrew asks about tasks or priorities

## Data Source
- **Todoist REST API v2** (read-only via personal token in .env)
- Cross-reference: MEMORY.md for yesterday's task state

## Procedure

### Step 1 — Get All Active Tasks
```bash
curl -s -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  "https://api.todoist.com/rest/v2/tasks"
```
For each task, note:
- Task content (title)
- Project it belongs to
- Priority level (1=normal, 4=urgent)
- Due date (if set)
- Whether it's overdue

### Step 2 — Get Completed Tasks (Last 24 Hours)
```bash
curl -s -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  "https://api.todoist.com/sync/v9/completed/get_all?since=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S)"
```
Note which tasks were completed and in which projects.

### Step 3 — Identify Patterns
Compare against yesterday's memory:
- **Overdue tasks:** Tasks past their due date. How many? Which projects?
- **Completion velocity:** How many tasks completed today vs. typical day?
- **Workstream attention:** Which projects got task completions? Which are neglected?
- **Priority alignment:** Are P1 tasks getting done, or are P3 tasks being cherry-picked?
- **Stale projects:** Projects with open tasks but no completions for >5 days

### Step 4 — Cross-Reference Weekly Focus
If the vault-observer identified weekly focus areas, check whether Todoist activity aligns:
- Are tasks in the focus-area projects getting completed?
- Are non-focus projects consuming disproportionate attention?

## Output
Pass observations to memory-writer. Format:
```
[TASKS] 23 active tasks across 8 projects. 4 overdue (oldest: 3 days).
[TASKS] Completed today: 5 tasks — Stream API (2), Marketing (2), Fletch (1)
[TASKS] Neglected: Database-Completion has 6 open tasks, 0 completions in 8 days
[TASKS] Weekly alignment: Stream API focus is reflected in completions. Marketing on track. Terminal has 0 activity despite being P2.
```

## What NOT to Do
- Do not write full task lists to memory. Summarize counts and patterns.
- Do not call the Todoist API more than once per daily cycle.
- Do not make any write calls to Todoist. V1 is read-only.
- Do not nag Andrew about overdue tasks. Log observations silently.
- Do not rank or prioritize tasks for Andrew in V1. That's a V2 capability.

## Error Handling
- If Todoist API returns an error, skip this skill for today's cycle.
- Log the error: `[TASKS] Todoist API error: {status_code}. Skipped.`
- Do not retry more than once.
