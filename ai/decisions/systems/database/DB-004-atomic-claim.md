---
id: DB-004
title: "A once-only side effect claims a timestamp first"
system: database
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# DB-004 — A once-only side effect claims a timestamp first

## Decision

A side effect that must happen exactly once (an email, a tracking event, a campaign
launch, a webhook to a third party) first claims a nullable `*_at` column with
`UPDATE … SET x_at = now() WHERE id = ? AND x_at IS NULL`. Only the caller whose update
touched a row proceeds; a failure releases the claim so a later run retries.

## Why

Retries, double clicks, two devices and overlapping workers all reach the same code;
a read-then-write check lets two of them through.

## Consequences

- A `sent` flag set after the side effect, or a read-then-write check, is a finding.
- An admin resend forces the side effect without clearing history.
