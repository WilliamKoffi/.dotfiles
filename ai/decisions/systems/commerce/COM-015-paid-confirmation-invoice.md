---
id: COM-015
title: "A receipt at placement, a confirmation with the invoice at payment"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: [COM-014, DB-004]
supersedes: null
---
# COM-015 — A receipt at placement, a confirmation with the invoice at payment

## Decision

Placing an order sends a receipt. Payment sends a confirmation email with the invoice PDF
attached, triggered by the "order paid" event and claimed once. A failed send is logged
and retried; the order and invoice stay committed.

## Why

The customer holds the invoice without logging in, and a payment notified twice never
sends two emails.

## Consequences

- The admin can force a resend.
