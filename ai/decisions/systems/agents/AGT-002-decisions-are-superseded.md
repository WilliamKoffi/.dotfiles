---
id: AGT-002
title: "A decision is never edited, only superseded"
system: agents
status: locked
date: 2026-09-27
conflicts: []
requires: [AGT-001]
supersedes: null
proven_in:
  - lmdl docs/decisions/README.md
  - vente docs/decisions/README.md
  - workstation skill SKILL.md rule 9
---
# AGT-002 — A decision is never edited, only superseded

## Decision

Decisions live in `docs/decisions/`, one file each, numbered, with a register table in
its `README.md`. A locked decision is never edited. A change is a new decision that names
the one it supersedes; the old one's status becomes `superseded by NNN`, the only edit
allowed. Every decision names its `Source`: a file and line, a command's output, a commit,
a shared decision id, or `the user, <date>`.

## Why

Editing a decision erases why the old choice was made and when it stopped holding.
A source keeps a decision honest: one the repository does not follow is worse than none.

## Consequences

- Check the register before any structural choice.
- Both the old and the new decision stay in the register.
