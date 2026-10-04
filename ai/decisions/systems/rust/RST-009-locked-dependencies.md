---
id: RST-009
title: "`Cargo.lock` is committed and `cargo deny` runs"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# RST-009 — `Cargo.lock` is committed and `cargo deny` runs

## Decision

`Cargo.lock` is committed, builds use `--locked`, and `cargo deny` checks licences, advisories
and duplicates from a `deny.toml`. A new dependency is added with `default-features = false`
and only the features it needs.

## Why

The build is the same everywhere, and a vulnerable or duplicate crate is caught before it
ships.

## Consequences

- `cargo tree -d` is read when a duplicate appears.
