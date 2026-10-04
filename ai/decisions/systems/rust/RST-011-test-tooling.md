---
id: RST-011
title: "Tests run with nextest, properties with proptest"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# RST-011 — Tests run with nextest, properties with proptest

## Decision

Tests run with `cargo-nextest`. Business values (amounts, quantities, offline records) get
`proptest` properties; enum results are checked with `assert_matches!`. Every fixed bug gets a
regression test.

## Why

nextest isolates tests in processes and runs them in parallel; properties find the edge cases
examples miss.

## Consequences

- `cargo test --doc` still runs doc tests, which nextest does not.
