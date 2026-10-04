---
id: OPS-002
title: "A cheap ping and a real health check"
system: ops
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# OPS-002 — A cheap ping and a real health check

## Decision

`GET /ping` is liveness: it touches nothing. `GET /health` is readiness: public and
rate-limited, it runs a database `select 1` and a short cache write, read and delete,
returns each component's status only, and answers 503 when one is down.

## Why

A load balancer needs a check that proves the dependencies work, without exposing
anything useful to an attacker.

## Consequences

- The health response carries no versions, hostnames or error messages.
