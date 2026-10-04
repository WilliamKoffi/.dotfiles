---
id: RST-001
title: "A workspace with one crate per feature slice"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: [STK-004]
supersedes: null
---
# RST-001 — A workspace with one crate per feature slice

## Decision

A Rust application is a Cargo workspace: one binary crate `app`, one shared crate `core`, and
one library crate per feature slice under `modules/`. Dependencies flow `app` → `modules/*` →
`core`; `core` never depends on a module, and a module depends on another only without a cycle.

## Why

A crate boundary makes the slice boundary a compile error instead of a review comment, and
`cargo check -p <slice>` rebuilds one slice.

## Consequences

- A cycle between two slices is broken by moving the shared part to `core` or by passing data in.
- `app` holds `main`, the router and nothing a slice could own.
