---
id: PHP-002
title: "Classes listed as data are written fully qualified"
system: php
status: locked
date: 2026-09-28
conflicts: []
requires: []
supersedes: null
---
# PHP-002 — Classes listed as data are written fully qualified

## Decision

Wherever a class name is a value rather than a type, it is written with its fully qualified
name and the leading `\`, even when the same class is imported for a type elsewhere in the file:

- **arrays of classes**, one per line: `[\App\Http\Auth::class, …]`;
- **type-to-class maps**, such as the `match` that resolves a polymorphic type:
  `self::Sale => \App\Sales\Sale::class`;
- **variadic arguments that list classes**: `migrate(\App\Sales\CreateSalesTable::class, …)`;
- **configuration files** that return lists of classes (middleware, discovery exclusions);
- **attribute arguments** that name a class: `#[Middleware(\App\Auth\RequireTenant::class)]`.

## Why

A list of classes is read as a registry: the full name shows each entry's origin in place
and keeps the import block about types only.

## Consequences

- `extends`, `implements`, parameter and return types, `instanceof`, `catch`, container
  bindings and PHPDoc types keep ordinary imports.
- Native functions and constants are not covered by this rule.
