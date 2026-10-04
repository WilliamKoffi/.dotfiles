---
id: COM-002
title: "The order total is fixed at placement and never edited once paid"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: [COM-001]
supersedes: null
---
# COM-002 — The order total is fixed at placement and never edited once paid

## Decision

The total is computed and stored once, when the order is placed. Adjustments may change
only while the order is unpaid, and each change recomputes the total. From payment on, the
total is the amount charged: a correction is a new adjustment row, never an edit.

## Why

The amount the customer paid must stay readable forever; an edited row loses what was
charged.

## Consequences

- `recalculate()` refuses once `paid_at` is set.
- The admin edits adjustments only while the order is unpaid.
