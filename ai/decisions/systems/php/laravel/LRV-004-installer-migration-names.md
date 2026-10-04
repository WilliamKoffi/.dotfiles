---
id: LRV-004
title: "Framework migrations keep their installer filenames"
system: php/laravel
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# LRV-004 — Framework migrations keep their installer filenames

## Decision

The migrations Laravel's installer creates keep their filenames
(`0001_01_01_000000_create_users_table.php` and the others in that series). Domain
migrations follow with dated names.

## Why

Stable filenames avoid conflicts with framework upgrades, and every Laravel developer
knows where the users table comes from.

## Consequences

- Renaming or re-dating a framework migration is a finding.
