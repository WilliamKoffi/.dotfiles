---
id: LRV-008
title: "Sanctum SPA cookie, not API tokens"
system: php/laravel
status: locked
date: 2026-09-28
conflicts: []
requires: []
supersedes: AUTH-001
---
# LRV-008 — Sanctum SPA cookie, not API tokens

## Decision

The browser front end and Laravel share a session through Sanctum's stateful cookie with
CSRF, not API tokens. Fortify runs in JSON mode.

## Why

Browser clients on a shared parent domain; no token storage in the browser.

## Consequences

- `statefulApi()`, `SANCTUM_STATEFUL_DOMAINS`, `SESSION_DOMAIN` are set.
- Account routes use `auth:sanctum`.
