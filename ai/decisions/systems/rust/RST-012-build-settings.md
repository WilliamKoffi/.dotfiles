---
id: RST-012
title: "Builds stay fast through the slice loop and two profile settings"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: [RST-001]
supersedes: null
---
# RST-012 — Builds stay fast through the slice loop and two profile settings

## Decision

The working loop is `cargo check -p <slice>` and `cargo test -p <slice>`, never `cargo clean`.
Dependency versions live once in `[workspace.dependencies]`, with `default-features = false`
where a feature is not used. The dev profile sets `debug = "line-tables-only"`; release sets
`lto = "thin"`. Any further tuning starts from `cargo build --timings`; duplicates are read with
`cargo tree -d`.

## Why

A slice crate rebuilds alone; line tables keep backtraces at a fraction of full debug info;
thin LTO gives most of the release gain without the link time of full LTO.

## Consequences

- No mold, clang, sccache or cargo-chef until a timing shows the need (`rust-lld` is the default
  linker; there is no CI).
- The layered workspace (`domain`/`infra`/`api`) is rejected: it contradicts STK-004.
