---
id: MNY-003
title: "Amounts are displayed through one shared formatter"
system: money
status: locked
date: 2026-09-27
conflicts: []
requires: [MNY-001]
supersedes: null
---
# MNY-003 — Amounts are displayed through one shared formatter

## Decision

Every displayed amount goes through one shared formatter (e.g. `formatXOF`, or the
API's `formatted` field). No component formats money on its own.

## Why

Grouping separators and the currency suffix differ by locale and engine; one function
keeps every screen identical.

## Consequences

- An inline `toLocaleString` or hand-built currency string is a finding.
