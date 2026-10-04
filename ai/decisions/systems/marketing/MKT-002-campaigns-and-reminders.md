---
id: MKT-002
title: "Campaigns and reminders check consent at every send"
system: marketing
status: locked
date: 2026-09-27
conflicts: []
requires: [MKT-001, DB-004]
supersedes: null
---
# MKT-002 — Campaigns and reminders check consent at every send

## Decision

Marketing email goes only to active subscribers, checked at launch and again at each
send, so an unsubscribe is honoured mid-campaign. Audiences are a fixed list of segments,
never free SQL. Launching freezes the audience into one delivery row per address and queues
one send each; a launched campaign cannot be edited. Reminder rows (unique per subject and
step) are written before sending, so overlapping runs never double-send. Links carry UTM
tags; attribution is kept only with analytics consent.

## Why

Consent can change between launch and send, and duplicate marketing email costs
reputation.

## Consequences

- Every email carries a signed unsubscribe link and a `List-Unsubscribe` header.
- Sends are queued; a queue worker is required (OPS-001).
