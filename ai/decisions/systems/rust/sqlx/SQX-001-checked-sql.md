---
id: SQX-001
title: "SQL is written raw and checked at compile time"
system: rust/sqlx
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# SQX-001 — SQL is written raw and checked at compile time

## Decision

Queries are raw SQL through `sqlx::query!`/`query_as!`, checked against the schema at compile
time (or from the offline cache). A transaction is passed as `&mut`; one not committed rolls back
when dropped.

## Why

The SQL a reviewer reads is the SQL that runs, and a renamed column breaks the build.

## Consequences

- The offline cache (`.sqlx/`) is committed so builds need no database.
