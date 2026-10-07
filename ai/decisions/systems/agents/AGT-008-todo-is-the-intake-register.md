---
id: AGT-008
title: "`todo.md` is the intake register; a task ticks its line when it completes"
system: agents
status: locked
date: 2026-10-07
conflicts: []
requires: [AGT-003]
supersedes: null
---
# AGT-008 — `todo.md` is the intake register; a task ticks its line when it completes

## Decision

- `todo.md` owns the raw wishlist. An item is written there first, in the user's own words.
- A scoped task created from an item names it: `source: todo.md:NN` and `todo_line: NN`.
- When that task completes, its line is ticked (`- [ ]` → `- [x]`) in the same commit. That tick
  is the only thing the protocol ever writes back to `todo.md`.
- One item may produce several tasks; each names the same line, and the line is ticked when the
  last of them completes.

## Why

Two registers that do not name each other drift. `todo.md` answers "what does the user still
want", `tasks/` answers "what is scoped and runnable now".

## Consequences

- An item too vague to scope stays unticked with no task: the signal that it needs a decision or a
  question, not a worker.
