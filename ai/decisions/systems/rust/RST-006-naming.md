---
id: RST-006
title: "Names are one English word; a domain noun is a folder"
system: rust
status: locked
date: 2026-10-05
conflicts: []
requires: [LNG-004]
supersedes: null
---
# RST-006 — Names are one English word; a domain noun is a folder

## Decision

- Every name we write is one English word: types, traits, fields, variables, functions,
  modules, files. `TenantId` is `id::Tenant`; `is_ulid` is `ulid::valid`.
- A domain noun is a folder, a vertical slice: `name.rs` composes `name/`, and each type in it
  is one word that the folder qualifies (`id/tenant.rs` holds `Tenant`, used as `id::Tenant`).
  A type is not prefixed by its module (`sales::Item`, not `SaleItem`).
- Our own methods carry no `as_`, `to_`, `is_` or `has_` prefix: an accessor is named by what it
  gives (`text()`), a predicate by its adjective (`valid`), an action by its verb. No `set_`.
- No abbreviation except `id`, `url`, `http`.
- A boolean parameter becomes an enum; three or more parameters become a struct.
- A string that names something (a setting, a role, a code) comes from one enum, never repeated
  as a literal across the code.

## Exempt

Names a trait or an external API imposes (`into_response`, `from_str`, `as_str` on `str`),
generated code (RST-010), wire names of the contract (`server_time`), and test functions, whose
names are sentences.

## Why

Short names read as prose at the call site; the folder already qualifies a type, and one place
per name keeps a rename to one edit.

## Consequences

- `module_name_repetitions` (RST-005) checks the prefix rule; review checks the rest.
