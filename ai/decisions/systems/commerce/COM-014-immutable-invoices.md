---
id: COM-014
title: "Invoices are immutable snapshots issued once per paid order"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: [COM-002, MNY-001]
supersedes: null
---
# COM-014 — Invoices are immutable snapshots issued once per paid order

## Decision

An invoice is issued once per paid order (unique order key), from an "order paid" event,
so the order module does not depend on billing. It copies prices, lines, customer, tax rate
and seller details at issuance and is never edited. Tax is allocated in integers so
`net + tax = total` for the invoice and every line. A refund issues a credit note that
never changes the invoice or the order. Documents (PDF) are rendered from the snapshot,
never from current data.

## Why

An invoice is a legal record of what was sold; rebuilding it from today's data rewrites
history.

## Consequences

- The tax rate and seller details are configuration, confirmed legally before launch.
- The invoice number sequence is atomic, per year.
