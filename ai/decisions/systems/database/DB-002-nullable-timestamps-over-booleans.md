---
id: DB-002
title: "Nullable *_at timestamps over booleans"
system: database
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# DB-002 — Nullable *_at timestamps over booleans

## Decision

Lifecycle and scheduling states are nullable `*_at` columns, never booleans:
`published_at`, `paid_at`, `shipped_at`, `approved_at`, `revoked_at`. A state derivable
from other columns is a method, not a column.

## Why

A timestamp answers both "is it?" and "since when?"; a boolean loses the second.

## Consequences

- A new `is_*` column is a finding unless no date can apply.
