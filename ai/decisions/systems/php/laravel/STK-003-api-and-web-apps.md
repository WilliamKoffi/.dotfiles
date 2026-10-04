---
id: STK-003
title: "Two applications: Laravel api/, Nuxt web/"
system: php/laravel
status: retired
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# STK-003 — Two applications: Laravel api/, Nuxt web/

## Decision

Laravel lives in `api/` and Nuxt in `web/`, side by side at the repository root.
Laravel serves JSON, webhooks and the admin; Nuxt renders every customer page.

## Why

Same layout across projects, so code and agent scopes copy over without path changes.

## Consequences

- No storefront Blade views.
- Agent scopes are rooted at `api/` or `web/`.
