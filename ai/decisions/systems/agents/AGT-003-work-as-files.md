---
id: AGT-003
title: "Work is tracked as files in tasks/, problems in findings/"
system: agents
status: locked
date: 2026-09-27
conflicts: []
requires: [AGT-002]
supersedes: null
proven_in:
  - lmdl AGENTS.md §2
  - intelli-resume ADR-025
---
# AGT-003 — Work is tracked as files in tasks/, problems in findings/

## Decision

Work is one YAML file per task under `tasks/`; the folder is the status (`backlog`,
`ready`, `running`, `blocked`, `completed`, `failed`). A task names its `scope`, its
`depends_on` and a checkable `done_when`. A problem seen outside the current task is a file
in `findings/` with `file:line` evidence, not a fix in passing. Role contracts live in
`agents/<role>/AGENT.md`. The `workstation` skill runs this protocol.

## Why

Untyped todo lines have no owner, scope or check. Fixing things in passing widens every
diff; filing them keeps changes scoped.

## Consequences

- One commit per completed task: `TASK-NNN: <title>`.
- Trivial changes need no task.
