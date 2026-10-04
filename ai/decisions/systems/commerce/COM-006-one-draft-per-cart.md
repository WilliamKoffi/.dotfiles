---
id: COM-006
title: "At most one draft order per cart; old drafts are pruned"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: [COM-005]
supersedes: null
---
# COM-006 — At most one draft order per cart; old drafts are pruned

## Decision

A draft order points to its cart with a unique, nullable `cart_id`; placing the order
clears it so the cart can start a new checkout. Draft-only columns (destination, gateway)
are nullable and required at placement. A daily command deletes drafts older than a set
age (7 days by default).

## Why

Without a unique key, every visit to checkout creates an order, and abandoned drafts
pile up.

## Consequences

- Pruning touches drafts only; placed but unpaid orders are handled by payment reconciliation (PAY-004).
