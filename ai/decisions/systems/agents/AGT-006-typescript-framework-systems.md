---
id: AGT-006
title: "TypeScript gains Solid and React folders, each with its query folder"
system: agents
status: proposed
date: 2026-10-07
conflicts: []
requires: []
supersedes: null
---
# AGT-006 — TypeScript gains Solid and React folders, each with its query folder

## Decision

The closed list of systems gains `ts/solid` (prefix `SLD`, Solid code shape), `ts/solid-query`
(`TSQ`, TanStack Query on Solid), `ts/react` (`RCT`, React code shape, whatever framework runs on
React) and `ts/react-query` (`RQY`, TanStack Query on React).

## Why

A convention on a framework's state primitives had no folder to live in, and one on a query
library's results cannot share its framework's folder: a decision never pairs two frameworks
(rule 7).

## Consequences

- Their decisions are offered only to projects that choose that framework or library; a framework
  built on React takes the `ts/react` decisions.
- A new TypeScript library folder is a new `AGT` decision.
