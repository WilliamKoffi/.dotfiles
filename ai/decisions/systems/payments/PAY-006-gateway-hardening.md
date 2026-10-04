---
id: PAY-006
title: "Gateway calls fail closed"
system: payments
status: locked
date: 2026-09-27
conflicts: []
requires: [PAY-001, PAY-003]
supersedes: null
---
# PAY-006 — Gateway calls fail closed

## Decision

A webhook's signature is checked before anything is written, and an empty secret rejects
every call. The sandbox gateway is refused in production. Customers are redirected only to
the storefront or an allow-listed gateway host. A payment arriving after its order was
cancelled is left unhandled and flagged for a manual refund, never lost and never
silently settled.

## Why

A trusting fallback is the easiest way to mark orders paid for free.

## Consequences

- Business refusals answer 4xx and stay visible in the admin; only transient errors invite a retry.
