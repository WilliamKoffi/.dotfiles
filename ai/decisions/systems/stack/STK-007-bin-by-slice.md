---
id: STK-007
title: "Scripts live in `bin/<slice>/<word>.sh`"
system: stack
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# STK-007 — Scripts live in `bin/<slice>/<word>.sh`

## Decision

Shell scripts live in the repository's `bin/`, grouped by slice (`bin/database/`), each named
with one English word and the `.sh` extension (`bin/database/up.sh`).

## Why

Scripts are found in one place, by what they act on, and their names stay short.

## Consequences

- A script used by one package only still goes to `bin/<slice>/`.
