---
id: PAY-001
title: "Payment gateways sit behind one interface"
system: payments
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
proven_in:
  - intelli-resume ADR-024
  - ka-cosmetics D52
---
# PAY-001 — Payment gateways sit behind one interface

## Decision

The app talks to one payment interface (start, check, verify, parse); each provider is
one adapter selected by configuration. Payment truth comes from asking the gateway: the
webhook only prompts that check. A payment settles once.

## Why

Providers change; a new one should be one adapter, with routes, tables and UI untouched.
Webhooks can be replayed or lost.

## Consequences

- Unit conversion for the provider lives in the adapter (MNY-001).
- Replays and late notifications cannot flip a settled payment.
