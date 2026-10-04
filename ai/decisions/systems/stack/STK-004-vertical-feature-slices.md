---
id: STK-004
title: "Code is organised as vertical feature slices"
system: stack
status: proposed
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# STK-004 — Code is organised as vertical feature slices

## Decision

Behaviour is grouped by feature (`features/<feature>/` holding its components, state,
API calls and tests), not by technical layer. Shared code lives in one `shared/` area.

## Why

A change to one feature stays inside one folder, and an agent's scope can be one folder.

## Consequences

- A cross-feature import goes through `shared/`.
- Status stays `proposed` until the user locks it.
