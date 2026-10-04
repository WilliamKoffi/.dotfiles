---
id: COM-012
title: "Returns are their own module, with manual gateway refunds"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: [COM-013]
supersedes: null
---
# COM-012 — Returns are their own module, with manual gateway refunds

## Decision

Returns own the return request, its lines and the refund. The order only exposes which
paid, delivered lines may be returned. A customer may ask within a set window after
delivery; lifecycle (requested, approved, rejected, received, refunded) is timestamps, and
rejection carries a reason. Each request is a refund or an exchange. A gateway refund is
recorded as a manual settlement until a verified refund API exists. Only lines marked
restockable return to stock, through the stock authority.

## Why

Return state on the order would couple two lifecycles. A guessed gateway call can move
real money wrongly.

## Consequences

- Receiving a return never moves stock by itself.
- A stranger asking about someone else's order gets the same 404 as an unknown one.
