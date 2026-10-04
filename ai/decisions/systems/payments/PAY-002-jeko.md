---
id: PAY-002
title: "Jeko Africa is the payment gateway"
system: payments
status: locked
date: 2026-09-27
conflicts: []
requires: [PAY-001]
supersedes: null
---
# PAY-002 — Jeko Africa is the payment gateway

## Decision

Jeko Africa collects online payments (mobile money) in XOF.

## Why

Mobile money is how customers in the XOF zone pay, and Jeko collects it through one API.

## Consequences

- Jeko counts XOF in hundredths: the ×100 happens only in its adapter.
- Shared Jeko keys mean a webhook can receive another app's notifications: unknown
references are acknowledged and ignored.
