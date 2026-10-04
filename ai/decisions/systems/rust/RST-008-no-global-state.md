---
id: RST-008
title: "No global state, minimal `pub`, traits only when shared"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# RST-008 — No global state, minimal `pub`, traits only when shared

## Decision

Connections, configuration and clients are passed in (application state, parameters), never
held in a `static` or `LazyLock`. Items are private unless another crate uses them. A trait exists
only when two real implementations do.

## Why

Explicit dependencies keep tests independent and the call graph readable.

## Consequences

- A test builds its own state instead of resetting a global one.
