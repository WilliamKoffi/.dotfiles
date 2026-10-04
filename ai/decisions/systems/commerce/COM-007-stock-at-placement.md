---
id: COM-007
title: "Stock is taken at placement and returned only by cancel"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# COM-007 — Stock is taken at placement and returned only by cancel

## Decision

Stock is decremented when the order is placed and restored through `$order->cancel()`,
the only path that frees stock. No reservation table, no timed holds.

## Why

One place takes stock and one place returns it; holds and their expiry add state that
fails silently.

## Consequences

- `cancel()` is idempotent (guarded on `cancelled_at`).
- Expiring an unpaid order calls `cancel()`, never a separate restock.
