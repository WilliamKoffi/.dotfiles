---
id: MNY-001
title: "Money is an unsigned integer in the currency's smallest unit"
system: money
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
proven_in:
  - ka-cosmetics D5, D50
  - lmdl 005
  - intelli-resume ADR-024
---
# MNY-001 — Money is an unsigned integer in the currency's smallest unit

## Decision

Money is stored and computed as an unsigned integer in the currency's smallest unit
(XOF has none: whole francs, zero decimals). No floats, no decimals columns. A gateway that
counts differently converts inside its adapter only.

## Why

Integers avoid rounding errors; one unit everywhere avoids `amount * 100` leaking into
the app.

## Consequences

- Laravel: `unsignedBigInteger` read through a shared `Money` cast.
- The API sends integers; formatting is separate (MNY-003).
