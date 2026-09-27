---
id: STK-002
title: "Bun is the package manager and script runner"
system: stack
status: locked
date: 2026-09-27
conflicts: [STK-001]
requires: []
supersedes: null
proven_in:
  - vente 004
  - intelli-resume ADR-002
---
# STK-002 — Bun is the package manager and script runner

## Decision

Install with `bun install`, run with `bun run`, add with `bun add`. `bun.lock` is the
only lockfile; npm is never used.

## Why

Two lockfiles mean two dependency graphs and a build that differs by who ran it. Bun is
also the runtime and test runner where the project uses it.

## Consequences

- Every Validation command calls `bun run`.
- A tracked `package-lock.json`, `yarn.lock` or `pnpm-lock.yaml` is a finding.
