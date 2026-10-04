---
id: COM-009
title: "Coupon usage is counted from redemptions"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: [COM-001]
supersedes: null
---
# COM-009 — Coupon usage is counted from redemptions

## Decision

Each placed order that uses a coupon writes one `coupon_redemptions` row (unique on
coupon and order); cancelling the order deletes it. A coupon's capacity is `threshold`
(minimum spend), `limit` (global uses) and `quota` (uses per customer), and the coupon
answers `discount()`, `drained()` and `exhausted($shopper)`.

## Why

A counter column drifts on cancels and retries; counting rows cannot.

## Consequences

- A `used_count` column on the coupon is a finding.
- The discount reaches the order as an adjustment row (COM-001).
