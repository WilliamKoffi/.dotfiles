---
id: OPS-003
title: "The app ships a backup command; the operator owns the rest"
system: ops
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# OPS-003 — The app ships a backup command; the operator owns the rest

## Decision

A scheduled command writes compressed database and media archives and prunes old ones;
`--verify=<path>` checks an archive. Encryption, offsite copies, failure monitoring and
restores are the operator's job, and the restore procedure is documented and tested.

## Why

The app knows what to save; only the operator can hold keys and a second location.

## Consequences

- The app never deletes live data during a restore on its own.
