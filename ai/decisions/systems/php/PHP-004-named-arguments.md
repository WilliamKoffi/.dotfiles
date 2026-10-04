---
id: PHP-004
title: "Arguments are always passed by name"
system: php
status: locked
date: 2026-09-28
conflicts: []
requires: []
supersedes: null
---
# PHP-004 — Arguments are always passed by name

## Decision

Every argument is passed by name, in every call: functions, methods, constructors, static
calls, enum helpers and attributes, even when there is only one.

```php
$sale->pay(payment: $payment);
$status = Status::from(value: $row['status']);
#[HasMany(ownerJoin: 'item_id')]
```

The one exception is what the language cannot name: arguments bound to a variadic parameter
(`...$classes`) and arguments unpacked with `...`.

## Why

A call reads without opening the signature, and a literal (`true`, `null`, `3`) never loses
its meaning.

## Consequences

- A parameter name is part of the contract: renaming one breaks every caller. Parameters get
  short, stable names.
- A dependency that renames a parameter breaks the build; its version is pinned and bumped
  deliberately.
- PHP forbids a positional argument after a named one, so a call that mixes the two can only
  do it when the positional ones come first, which is the variadic case above.
- No standard fixer enforces this; it needs a custom lint rule.
