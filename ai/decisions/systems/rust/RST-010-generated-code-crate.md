---
id: RST-010
title: "Generated code lives in its own crate"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# RST-010 — Generated code lives in its own crate

## Decision

Code produced by a generator is placed in a crate of its own, never edited by hand, with the
strict lints relaxed for that crate only; other crates re-export what they need from it.

## Why

Generated code cannot meet hand-written lints, and isolating it keeps them strict elsewhere.

## Consequences

- Regenerating is one command; a check fails when the committed output is stale.
