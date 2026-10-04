---
id: SQX-002
title: "Database tests use `#[sqlx::test]`"
system: rust/sqlx
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# SQX-002 — Database tests use `#[sqlx::test]`

## Decision

A test that touches the database is `#[sqlx::test]`: a fresh database per test, with the
migrations applied.

## Why

Tests never share rows, so they run in parallel and in any order.

## Consequences

- Fixtures are seeded inside the test, not by a shared script.
