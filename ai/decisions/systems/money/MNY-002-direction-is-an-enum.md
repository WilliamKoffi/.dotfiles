---
id: MNY-002
title: "The direction of money is an enum, never a sign"
system: money
status: locked
date: 2026-09-27
conflicts: []
requires: [MNY-001]
supersedes: null
proven_in:
  - ka-cosmetics D16
  - lmdl 006
---
# MNY-002 — The direction of money is an enum, never a sign

## Decision

A money column is never negative. When a value subtracts (adjustment, refund), an
`operation` enum (`add` | `subtract`) sits beside an unsigned `amount`.

## Why

A sign in a money column hides intent and invites bugs.

## Consequences

- A negative money value is a bug.
