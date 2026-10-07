---
id: STK-010
title: "File size and splitting follow the grain convention"
system: stack
status: locked
date: 2026-10-07
conflicts: []
requires: []
supersedes: RST-014
---
# STK-010 — File size and splitting follow the grain convention

## Decision

Every source and test file we write, in any language, follows §3 of the grain convention,
[`~/.dotfiles/ai/skills/grain/shared/convention.md`](~/.dotfiles/ai/skills/grain/shared/convention.md):
its size limit (§3.1), its split by role rather than by type (§3.2), and its ruling on index
files (§3.3). Grain owns those rules; this decision adopts them and never restates them.

## Why

One rule for every language, kept in one place (AGT-001): a change to the limit or to the split
is made once, in grain, and every project that took this decision follows it.

## Consequences

- RST-014 is superseded: Rust files follow the same grain rules.
- Generated code is exempt.
- A file already past the limit is brought under through the grain pipeline (`/grain:survey`
  first), never as a side effect of an unrelated change; until then a change must not make it
  longer.
