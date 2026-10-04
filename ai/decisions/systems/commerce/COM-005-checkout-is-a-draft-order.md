---
id: COM-005
title: "Checkout is a draft order"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: [COM-003]
supersedes: null
---
# COM-005 — Checkout is a draft order

## Decision

There is no checkout module or checkout table. Checkout writes a draft order
(`placed_at IS NULL`), and each step (contact, address, delivery, payment) is a singleton
sub-resource with `show` and `update`. Placing the order stamps `placed_at`.

## Why

The steps need somewhere to keep state, and the order already owns every column they
fill.

## Consequences

- Each step refuses on the server when the previous step's column is empty; the client's route guard is a convenience only.
- Queries on real orders filter `placed_at IS NOT NULL`.
