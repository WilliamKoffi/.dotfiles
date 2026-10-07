---
id: RQY-001
title: "A query and a mutation are read through the same `State` shape"
system: ts/react-query
status: proposed
date: 2026-10-07
conflicts: []
requires: [RCT-001]
supersedes: null
---
# RQY-001 — A query and a mutation are read through the same `State` shape

## Decision

A `useQuery` result is wrapped by `State.query`: `get()` and `value` read its `data`, and the
query itself stays reachable for its status. A `useMutation` result is wrapped by
`State.mutation`: `set(variables)` runs `mutateAsync` and returns its promise, `get()` and `value`
read the last `data`, and the mutation stays reachable for its status.

## Why

Server state then reads at the call site as local state does under RCT-001, while the loading and
error status stays one property away.

## Consequences

- A `useQuery` or `useMutation` result used without the wrapper is a finding.
