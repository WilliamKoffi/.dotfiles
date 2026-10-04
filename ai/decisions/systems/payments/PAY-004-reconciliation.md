---
id: PAY-004
title: "A scheduled command reconciles pending payments"
system: payments
status: locked
date: 2026-09-27
conflicts: []
requires: [PAY-001]
supersedes: null
---
# PAY-004 — A scheduled command reconciles pending payments

## Decision

A scheduled, non-overlapping command asks the gateway about pending payments in a
window (older than 15 minutes, younger than 24 hours by default). A payment still pending
at the gateway after a set age (2 hours by default) expires, and its order is cancelled.

## Why

Webhooks get lost; asking the gateway is the only truth (PAY-001). The minimum age lets
real-time webhooks land first.

## Consequences

- Expiry cancels through the order, which returns stock (COM-007).
