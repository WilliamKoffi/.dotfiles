---
id: MKT-001
title: "Newsletter sign-up is single opt-in"
system: marketing
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# MKT-001 — Newsletter sign-up is single opt-in

## Decision

A newsletter sign-up is confirmed on submission (`confirmed_at` set to now), with no
confirmation email. `unsubscribed_at` records revocation; a subscription is never deleted
to unsubscribe.

## Why

A confirmation email needs a mail provider and a flow for a gain the product has not
asked for.

## Consequences

- Moving to double opt-in is a new decision that supersedes this one.
- Every email carries an unsubscribe link that sets `unsubscribed_at`.
