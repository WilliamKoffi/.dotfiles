---
id: COM-004
title: "The public order lookup returns minimal personal data"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# COM-004 — The public order lookup returns minimal personal data

## Decision

An order reachable by its reference alone (the payment return page, a guest's
confirmation) returns a masked email and coarse destination only: no phone, no street,
no delivery notes. Full details go to the authenticated owner or an admin.

## Why

Knowing a reference is a capability, not an identity; a leaked link must not leak an
address.

## Consequences

- The public and the owner's responses are two Resources, not one with conditionals.
- Totals, items, adjustments and payment timestamps stay public: they verify the order.
