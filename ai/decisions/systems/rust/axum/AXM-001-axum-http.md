---
id: AXM-001
title: "axum serves HTTP, with thin routes"
system: rust/axum
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# AXM-001 — axum serves HTTP, with thin routes

## Decision

HTTP is served by axum. A handler only extracts, calls the slice and renders; shared resources
come through `State`; timeouts and limits are `tower` layers. One error type renders the error
body of the API contract.

## Why

Thin handlers keep the behaviour testable without HTTP, and tower layers apply the same limits
to every route.

## Consequences

- Each slice exposes its own `Router`, merged in the binary.
