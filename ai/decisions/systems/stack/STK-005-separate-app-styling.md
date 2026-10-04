---
id: STK-005
title: "Storefront and admin styling never mix"
system: stack
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# STK-005 — Storefront and admin styling never mix

## Decision

The customer-facing app and the admin panel keep their own CSS and scripts. The admin's
CSS framework stays inside the panel; the storefront's stylesheets and animation libraries
never load in the admin.

## Why

Two apps with different audiences change at different speeds; a shared stylesheet
couples them and breaks one when the other moves.

## Consequences

- A storefront import of the admin's CSS framework, or the reverse, is a finding.
- Rewriting the storefront's CSS is a new decision, not a refactor.
