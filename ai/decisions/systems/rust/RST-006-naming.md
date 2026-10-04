---
id: RST-006
title: "Names are one English word, verbs for actions"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: [LNG-004]
supersedes: null
---
# RST-006 — Names are one English word, verbs for actions

## Decision

- A field or variable is one word; `is_`/`has_` only on a predicate method whose one word would
  read as a verb.
- `as_`, `to_`, `into_`, `from_` follow the language idiom and are exempt.
- No abbreviation except `id`, `url`, `http`.
- A boolean parameter becomes an enum; three or more parameters become a struct.
- No `set_` prefix: the method is named by its verb.
- A type is not prefixed by its module (`sales::Item`, not `SaleItem`).

## Why

Short names read as prose at the call site; the module already qualifies a type.

## Consequences

- `module_name_repetitions` (RST-005) checks the last rule.
