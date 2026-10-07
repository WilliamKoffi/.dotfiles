---
id: TSQ-001
title: "A query and a mutation are read through the same `State` shape"
system: ts/solid-query
status: proposed
date: 2026-10-07
conflicts: []
requires: [SLD-001]
supersedes: null
---
# TSQ-001 — A query and a mutation are read through the same `State` shape

## Decision

A `useQuery` result is wrapped by `State.query`: `get()` and `value` read its `data`, and the
query itself stays reachable for its status. A `useMutation` result is wrapped by
`State.mutation`: `set(variables)` runs the mutation and returns its promise (`mutate`, which
solid-query 6 makes promise-returning; `mutateAsync` before it), `get()` and `value`
read the last `data`, and the mutation stays reachable for its status.

## Why

Server state then reads at the call site as local state does under SLD-001, while the loading and
error status stays one property away.

## Consequences

- A `useQuery` or `useMutation` result used without the wrapper is a finding.
- The wrappers read the result's properties inside their getters, so every read stays tracked.
