---
id: COM-010
title: "Delivery methods are a table; price and carrier cost stay apart"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: [COM-001]
supersedes: null
---
# COM-010 — Delivery methods are a table; price and carrier cost stay apart

## Decision

Delivery methods are rows (`slug`, `name`, `zone`, `carrier`, `amount` the customer
pays, `cost` the carrier charges, `position`, `visible_at`), managed in the admin. At
placement the price becomes a `shipping` adjustment on the order, and the carrier and
cost are copied to the delivery.

## Why

Tariffs change without a deploy, and margin on shipping stays measurable because price
and cost are never the same number.

## Consequences

- Rows seeded before real tariffs exist are labelled as placeholders.
