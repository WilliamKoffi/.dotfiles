---
id: TST-001
title: "Playwright runs the end-to-end tests"
system: testing
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
proven_in:
  - ka-cosmetics D26
  - lmdl 008
---
# TST-001 — Playwright runs the end-to-end tests

## Decision

`@playwright/test` runs customer journeys, the selector contract and visual parity.

## Why

One browser runner for behaviour and screenshots.

## Consequences

- Unit tests use the stack's own runner (Pest, Vitest or `bun test`).
