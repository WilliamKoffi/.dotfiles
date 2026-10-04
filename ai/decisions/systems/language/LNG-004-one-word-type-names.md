---
id: LNG-004
title: "Models and enums are named in one word"
system: language
status: locked
date: 2026-09-28
conflicts: []
requires: []
supersedes: null
---
# LNG-004 — Models and enums are named in one word

## Decision

- A model or an enum is named with **one word** (`Task`, `Status`), never a compound
  (`TaskStatus`, `SaleItem`). The namespace carries the context: `App\Sales\Item`,
  `App\Tasks\Status`.
- Model methods and enum cases are one word **as far as possible** (`pay()`, `case Partial`);
  a second word is spent only when no single word is clear.

## Why

The namespace already says what a name belongs to; repeating it in the class name makes
every reference longer without adding meaning.

## Consequences

- Several classes share a short name (`Status`, `Item`) in different namespaces. When two meet
  in one file, the non-imported one is written fully qualified rather than given a compound alias.
- A one-word name that is a reserved word of the language cannot be used; the closest clear
  single word is chosen instead.
- A framework that derives table or key names from the class name gets an explicit table or
  key wherever the one-word name would derive the wrong one.
