---
id: DB-001
title: "ULID primary keys"
system: database
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# DB-001 — ULID primary keys

## Decision

Every table with an `id` uses a ULID (`ulid('id')->primary()`, `foreignUlid`).

## Why

Ids are not guessable and can be created before insert.

## Consequences

- Public URLs still use slugs or references, not ids.
