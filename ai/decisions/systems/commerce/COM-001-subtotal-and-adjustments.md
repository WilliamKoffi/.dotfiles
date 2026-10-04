---
id: COM-001
title: "An order stores subtotal and total; every other line is an adjustment"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: [MNY-002]
supersedes: null
---
# COM-001 — An order stores subtotal and total; every other line is an adjustment

## Decision

The order row holds `subtotal` and `total` only. Shipping, discounts and waivers are rows
in `order_adjustments` (a type, an unsigned `amount`, an `operation`):
`total = subtotal + Σ add − Σ subtract`.

## Why

A new kind of charge or discount is a new adjustment type, not a new column, and the
order's breakdown reads from one table.

## Consequences

- A `discount_total`, `shipping_total` or similar column on the order is a finding.
- The operation is derived from the adjustment type, not passed separately.
