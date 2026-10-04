---
id: AGT-001
title: "One owner per fact; AGENTS.md is a map"
system: agents
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# AGT-001 — One owner per fact; AGENTS.md is a map

## Decision

Each fact has exactly one owning file. Every other file links to the owner and never
restates it. `AGENTS.md` is the entry point and a map: it routes to the owners and holds
no rule of its own. `CLAUDE.md` and `GEMINI.md` are stubs that import `AGENTS.md`.

## Why

Restated facts drift apart, and agents then act on the stale copy.

## Consequences

- `AGENTS.md` carries an owner table (fact → file).
- A fact found in two files is a finding.
- Tool-managed marker blocks (graft, `next dev`) stay inside `AGENTS.md` as written.
