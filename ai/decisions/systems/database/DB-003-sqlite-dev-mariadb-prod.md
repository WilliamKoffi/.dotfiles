---
id: DB-003
title: "SQLite in development and tests, MariaDB in production"
system: database
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# DB-003 — SQLite in development and tests, MariaDB in production

## Decision

Development and tests run on SQLite, production on MariaDB. Every migration goes through
the framework's schema builder and every query through the ORM, so the same code runs on
both engines.

## Why

SQLite needs no server, which makes setup and tests fast. The schema builder hides the
differences between the two engines.

## Consequences

- Hand-written engine-specific SQL is a finding.
- A feature only one engine supports (full-text, JSON operators) needs a guard and a test on both.
