---
id: AUTH-001
title: "Sanctum SPA cookie, not API tokens"
system: auth
status: locked
date: 2026-09-27
conflicts: []
requires: [STK-003]
supersedes: null
proven_in:
  - ka-cosmetics D34
  - lmdl 009
---
# AUTH-001 — Sanctum SPA cookie, not API tokens

## Decision

Nuxt and Laravel share a session through Sanctum's stateful cookie with CSRF, not API
tokens. Fortify runs in JSON mode.

## Why

Browser clients on a shared parent domain; no token storage in the browser.

## Consequences

- `statefulApi()`, `SANCTUM_STATEFUL_DOMAINS`, `SESSION_DOMAIN` are set.
- Account routes use `auth:sanctum`.
