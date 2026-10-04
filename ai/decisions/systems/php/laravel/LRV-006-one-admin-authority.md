---
id: LRV-006
title: "One authority says who is an admin"
system: php/laravel
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# LRV-006 — One authority says who is an admin

## Decision

One method on the user model answers "may this user administer?", read from one source
(an `admins` table or equivalent). The admin panel's gate (`canAccessPanel()`) and every
Policy call it.

## Why

Scattered checks drift. When the panel and the API ask the same question in two ways,
one of them will be wrong.

## Consequences

- An inline role check, an `is_admin` boolean read directly, or a second role source is a finding.
- A role system (`roles`, `role_user`) is a new decision that supersedes this one.
