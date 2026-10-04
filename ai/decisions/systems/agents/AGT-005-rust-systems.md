---
id: AGT-005
title: "Rust gets a language folder and three framework folders"
system: agents
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# AGT-005 — Rust gets a language folder and three framework folders

## Decision

The closed list of systems gains `rust` (prefix `RST`, Rust code shape on any framework),
`rust/axum` (`AXM`), `rust/sqlx` (`SQX`) and `rust/sea-query` (`SQY`).

## Why

Rust conventions were decided for an HTTP API and had no folder to live in; a decision tied to
one library belongs in that library's folder (rule 7).

## Consequences

- `rust` counts as a language from now on: its decisions are offered only to Rust projects.
- A new Rust library folder is a new `AGT` decision.
