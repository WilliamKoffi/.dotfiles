---
id: PAY-003
title: "Webhooks are stored raw first, upserted on gateway and reference"
system: payments
status: locked
date: 2026-09-27
conflicts: []
requires: [PAY-001]
supersedes: null
---
# PAY-003 — Webhooks are stored raw first, upserted on gateway and reference

## Decision

A payment notification is stored before it is verified, with `updateOrCreate` on
`(gateway, reference)` so a legitimate retry cannot crash on the unique key. The payload is
kept byte for byte; a rejection is written to `failure_reason`, never into the payload. The
webhook route sits under a `webhooks/*` path, outside the API prefix, and is exempted from
CSRF twice: by that path pattern and on the route itself.

## Why

A notification lost before storage cannot be investigated; a raw payload proves what
the gateway sent. Failed webhooks become queryable.

## Consequences

- Adding a gateway is a route and an adapter; the CSRF glob already covers it.
- The route-level exemption survives the path pattern being edited or the route moving.
