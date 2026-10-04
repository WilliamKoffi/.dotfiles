---
id: RST-004
title: "The toolchain is pinned in `rust-toolchain.toml`"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# RST-004 — The toolchain is pinned in `rust-toolchain.toml`

## Decision

Each workspace pins its Rust version and components (`rustfmt`, `clippy`) in
`rust-toolchain.toml` at its root.

## Why

Every machine and agent builds with the same compiler and the same lints.

## Consequences

- Raising the version is a commit of its own, with the new lints fixed in it.
