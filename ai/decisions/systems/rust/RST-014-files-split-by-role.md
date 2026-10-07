---
id: RST-014
title: "A file stays under 150 lines and splits by role"
system: rust
status: superseded by STK-010
date: 2026-10-05
conflicts: []
requires: [RST-001, RST-003, RST-006, RST-013]
supersedes: null
---
# RST-014 — A file stays under 150 lines and splits by role

## Decision

No Rust file we write is longer than 150 lines, tests included. A file that grows past it is
split by role, never by size alone: each noun or behaviour moves to its own file
(`claim.rs` keeps `Claim` and the `Pool` trait, `connection.rs` takes the `Connection` trait).
A group of files about one domain noun becomes a folder composed by `name.rs` (RST-003,
RST-006), and its tests follow the same split under `tests/` (RST-013).

The split runs at every scale: a workspace splits into one crate per slice (RST-001), a crate
into one folder per domain noun, a folder into one file per role.

## Why

A short file is read whole; a split by role keeps each name, and each change, in one place.

## Consequences

- Generated code (RST-010) is exempt.
- `wc -l` is part of the validation of every task that writes Rust.
