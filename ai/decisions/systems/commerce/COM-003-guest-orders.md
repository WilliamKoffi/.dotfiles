---
id: COM-003
title: "A guest order is a normal order"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# COM-003 — A guest order is a normal order

## Decision

Checkout needs no account. The order's customer key is nullable (`ON DELETE SET NULL`),
and the order stores its own contact `email`, required at placement when there is no
customer. The address is a snapshot on the order.

## Why

Forcing an account loses sales. A snapshot keeps the order correct after the customer
changes or deletes their profile.

## Consequences

- `$order->guest()` is `customer_id === null`; there is no `is_guest` column.
- No separate order-customer table: contact is the email column plus the nullable key.
