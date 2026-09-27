---
id: LNG-002
title: "Data keys are snake_case end to end"
system: language
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
proven_in:
  - lmdl conventions/api-contract.md:9
  - vente 003
---
# LNG-002 — Data keys are snake_case end to end

## Decision

Domain data keys are `snake_case` in the database, the API and the front end, with no
conversion layer between them.

## Why

One casing end to end means a key can be searched across every layer, and no mapper
can drift.

## Consequences

- API resources and request bodies use the column names.
- Front-end variables holding API data keep the keys unchanged.
