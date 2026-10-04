---
id: LRV-005
title: "Form Requests validate, Policies authorize, Resources serialize"
system: php/laravel
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# LRV-005 — Form Requests validate, Policies authorize, Resources serialize

## Decision

Laravel's own roles are the baseline: a Form Request validates input, a Policy
authorizes, an API Resource serializes. Value objects and DTOs are added only where they
carry real behaviour, never by reflex.

## Why

Each concern has one place a Laravel developer will look for it. Layers added by habit
cost indirection and buy nothing.

## Consequences

- Validation in a controller, an inline authorization check, or a hand-built response array is a finding.
- A new DTO names the behaviour it carries.
