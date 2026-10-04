---
id: MKT-006
title: "Ad pixels go through one tracker, set in the admin, after consent"
system: marketing
status: locked
date: 2026-09-27
conflicts: []
requires: [DB-004]
supersedes: null
---
# MKT-006 — Ad pixels go through one tracker, set in the admin, after consent

## Decision

Advertising and analytics platforms are configured in the admin, never in code. The
client loads a platform only when it is enabled and the visitor accepted its consent
category. Call sites use one tracker (`trackAddToCart`, `trackPurchase`…) and adapters
translate per platform. A purchase is tracked when the order is paid, claimed once, and
the server-side event shares its id with the browser event for deduplication. Secrets
(access tokens) are encrypted and never returned by any API.

## Why

Identifiers in code need a deploy to change; call sites that know each platform
multiply with every new one.

## Consequences

- A platform SDK called directly from a component is a finding.
