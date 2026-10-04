---
id: RST-003
title: "A module is `name.rs` beside `name/`, never `mod.rs`"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# RST-003 — A module is `name.rs` beside `name/`, never `mod.rs`

## Decision

A module with children is the file `name.rs` next to the folder `name/`. `mod.rs` is not used.
The `name.rs` file composes its folder: declarations and re-exports, no logic.

## Why

Editor tabs show a real name instead of a row of `mod.rs`, and the composing file is found next
to its folder.

## Consequences

- `clippy::mod_module_files` can enforce it.
