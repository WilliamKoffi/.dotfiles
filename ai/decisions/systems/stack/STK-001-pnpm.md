---
id: STK-001
title: "pnpm is the package manager"
system: stack
status: locked
date: 2026-09-27
conflicts: [STK-002]
requires: []
supersedes: null
---
# STK-001 — pnpm is the package manager

## Decision

Install, add and run scripts with `pnpm`. `pnpm-lock.yaml` is the only lockfile; npm is
never used.

## Why

Two lockfiles mean two dependency graphs and a build that differs by who ran it. pnpm
is strict about undeclared dependencies.

## Consequences

- Every Validation command calls `pnpm`.
- A tracked `package-lock.json`, `yarn.lock` or `bun.lock` is a finding.
