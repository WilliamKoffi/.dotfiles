---
id: COM-013
title: "One module owns stock, and every change is a movement"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# COM-013 — One module owns stock, and every change is a movement

## Decision

One module is the only one that changes available quantity. Every change writes a stock
movement row (reason, quantity, location when stock is per warehouse). Other modules
(orders, procurement, returns) call its methods and depend on it one way. Reorder state is
computed (`quantity <= reorder_point`), not stored.

## Why

Stock changed from several places cannot be audited or reconciled; the movement log
explains every number.

## Consequences

- A direct write to a stock column outside the owning module is a finding.
