---
id: DB-005
title: "Table and column names are the shortest clear noun"
system: database
status: locked
date: 2026-09-28
conflicts: []
requires: [LNG-002]
supersedes: null
---
# DB-005 — Table and column names are the shortest clear noun

## Decision

- **Tables** are a plain plural noun (`orders`, `clients`). A second word, the module or
  the parent, is added only when the bare noun would confuse or collide: `order_items`,
  not `items`.
- **At most one `_`** in a table or column name, unless a shorter name would be too hard
  to understand. The framework's own tables and columns are exempt.
- **Foreign keys** are `<table_singular>_id` (`client_id`), or a role word plus `_id` when
  the relation is named by its role (`parent_id`, `shipping_id`). The one-`_` rule wins over
  a two-word target table: `item_id`, not `order_item_id`.
- **Money columns** are named after what the money is, in one word when one word says it:
  `total`, `cost`, `price`. An `_amount` suffix is not forbidden, but is used only when one
  word would be ambiguous, typically a second figure beside an `amount` on the same row
  (`provider_amount`). `amount` alone is for rows that are themselves a money movement.

## Why

Short names stay readable in queries, relations and API keys alike; the extra word is
spent only where it prevents a misreading.

## Consequences

- A name with two `_` or a redundant `_amount` is a finding unless the shorter name was
  judged unclear.
- A relation method reads as the foreign key without its `_id` (`client_id` → `client()`).
