---
id: LRV-002
title: "Route leaves per module; middleware only in the index"
system: php/laravel
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# LRV-002 — Route leaves per module; middleware only in the index

## Decision

Routes live in `routes/api/<module>.php` and `routes/web/<module>.php`. Each directory has
an `index.php` that `require`s its leaves inside the middleware groups, and
`bootstrap/app.php` points `withRouting()` at both indexes. A module with two access
contracts (public and authenticated) has two leaves, named after the contract.

## Why

Middleware in one file makes the auth contract readable in one place. Routes loaded from
module providers spread it across every module, and a merge that drops one `auth:sanctum`
removes authentication with no failing test.

## Consequences

- A leaf that calls `->middleware()` is a finding.
- Module service providers load views, Filament, policies and config, never routes.
