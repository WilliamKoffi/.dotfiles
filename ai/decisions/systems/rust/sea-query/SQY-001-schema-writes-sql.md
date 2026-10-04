---
id: SQY-001
title: "The schema is written in Rust and emitted as committed SQL"
system: rust/sea-query
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# SQY-001 — The schema is written in Rust and emitted as committed SQL

## Decision

The schema is described with the sea-query builder in a crate of its own, with project helpers
for the repeated columns; what the builder cannot express (policies, grants) is raw SQL in the
same crate. Rust enums are the source of the enum types. One command writes the migrations as
`.sql` files, committed, one per table; a test regenerates them and fails on any difference. No
ORM is used to run them.

## Why

One source in Rust for enums and repeated columns, while the reviewed artefact stays plain SQL
any migration runner can apply.

## Consequences

- A hand edit to a generated `.sql` fails the regeneration test.
