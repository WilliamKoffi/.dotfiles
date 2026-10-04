---
id: LRV-007
title: "The personal access token table is kept for future clients"
system: php/laravel
status: locked
date: 2026-09-27
conflicts: []
requires: [AUTH-001]
supersedes: null
---
# LRV-007 — The personal access token table is kept for future clients

## Decision

The Sanctum `personal_access_tokens` migration stays, ready for a future mobile or
command-line client. The browser never uses tokens. A token client is added beside the
cookie login and may not weaken or replace it.

## Why

Removing the table saves nothing and costs a migration later; mixing tokens into the
browser flow reopens the XSS risk the cookie avoids.

## Consequences

- A token stored in browser storage is a finding.
