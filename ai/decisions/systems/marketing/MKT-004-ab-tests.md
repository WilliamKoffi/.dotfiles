---
id: MKT-004
title: "A/B tests assign by hash and recommend a winner only on significance"
system: marketing
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# MKT-004 — A/B tests assign by hash and recommend a winner only on significance

## Decision

A variant is `hash(subject id, test id) mod 100 < split`: stable across retries, stored
nowhere. A started test cannot be edited or deleted. Rates are shares of what was sent to
each variant. A winner is recommended only when each side reached a minimum sample and a
two-sided test passes 95%; the admin may still choose, with a warning.

## Why

Stored assignments can flip; peeking at noise picks losers.

## Consequences

- A test is never stopped the first time it looks significant.
