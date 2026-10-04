---
id: PAY-005
title: "One payment per order, one attempt per try"
system: payments
status: locked
date: 2026-09-27
conflicts: []
requires: [PAY-001]
supersedes: null
---
# PAY-005 — One payment per order, one attempt per try

## Decision

`payments` holds one row per order that owes money. Each initiation or retry inserts a
`payment_attempts` row, unique on `(gateway, reference)`; a retry never overwrites an
earlier attempt. Notifications link to their attempt. Status is derived from timestamps
(`paid_at`, `failed_at`), with no status string.

## Why

Overwriting an attempt loses the gateway reference a late webhook will quote. A stored
status drifts from the timestamps that prove it.

## Consequences

- A `status` column on payments is a finding.
