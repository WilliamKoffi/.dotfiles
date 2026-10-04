---
id: RST-007
title: "Domain values are validated newtypes"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# RST-007 — Domain values are validated newtypes

## Decision

An id, a hash or an amount is a newtype validated at construction (`TenantId`, `Amount`); a
function takes the newtype, never a raw `String` or integer. Arithmetic on amounts is checked,
and `overflow-checks = true` stays on in release.

## Why

An invalid value cannot reach the code past its constructor, and an overflow fails instead of
wrapping.

## Consequences

- Parsing happens once, at the edge (request, row).
