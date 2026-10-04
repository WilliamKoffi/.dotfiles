---
id: COM-016
title: "Order lines snapshot the unit cost; reports count paid orders only"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# COM-016 — Order lines snapshot the unit cost; reports count paid orders only

## Decision

Each product carries a current unit cost, updated as a weighted average on restock. Each
order line copies it at placement and it is never rewritten. Revenue, margin, lifetime
value and funnels count paid orders only. A line with an unknown cost (0) is left out of
profit, never estimated.

## Why

Profit computed from today's cost rewrites past margins; an estimate shown as exact
misleads.

## Consequences

- A report that includes unpaid orders in revenue is a finding.
