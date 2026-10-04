---
id: AGT-004
title: "Each phase ends with a blocking gate"
system: agents
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# AGT-004 — Each phase ends with a blocking gate

## Decision

A plan is cut into phases, and each phase ends with a gate written as a prohibition:
"phase N+1 may not start until <check> is green". The next phase starts only once the gate
has been verified, not assumed.

## Why

A gate written as a wish gets skipped under pressure; a prohibition with a check does
not.

## Consequences

- A gate names the command or test that proves it.
- Work found to belong to a closed phase reopens that phase's gate.
