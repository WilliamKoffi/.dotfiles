---
id: RST-005
title: "Strict workspace lints, warnings fail"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# RST-005 — Strict workspace lints, warnings fail

## Decision

Lints are set once in `[workspace.lints]`, inherited by every crate:
`clippy::pedantic` at `priority = -1`; `unsafe_code = "forbid"`; `unwrap_used`, `expect_used`,
`panic`, `todo`, `unimplemented`, `dbg_macro`, `indexing_slicing` denied outside tests;
`print_stdout`, `print_stderr`, `arithmetic_side_effects` warned; `module_name_repetitions` kept
on. `clippy -- -D warnings` makes every warning fail. A local exception is
`#[expect(lint, reason = "…")]`, never `#[allow]`. `nursery`, `unused_results` and `missing_docs`
are not enabled.

## Why

The compiler catches the shortcuts a reviewer would; `expect` with a reason fails once the
exception is no longer needed.

## Consequences

- Groups need `priority = -1` so single lints can override them.
- A lint is promoted from warn to deny after a few weeks without hits.
