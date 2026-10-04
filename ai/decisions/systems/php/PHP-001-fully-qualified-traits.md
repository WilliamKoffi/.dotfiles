---
id: PHP-001
title: "A trait is used by its fully qualified name"
system: php
status: locked
date: 2026-09-28
conflicts: []
requires: []
supersedes: null
---
# PHP-001 — A trait is used by its fully qualified name

## Decision

A trait is pulled into a class with its fully qualified name and the leading `\`, inside the
class body. It is never imported at the top of the file.

```php
final class Sale
{
    use \App\Support\HasUlid;
}
```

## Why

Top-of-file imports are kept for the types a class uses in its signatures; a trait is
behaviour mixed in, and its full name says where that behaviour comes from without a jump.

## Consequences

- The leading `\` is required, not style: inside a class body a qualified trait name resolves
  against the current namespace, so `use App\Support\HasUlid;` in `namespace App\Models` means
  `App\Models\App\Support\HasUlid`.
- No standard fixer enforces this; one that imports names (`fully_qualified_strict_types`)
  must be configured so it leaves trait uses alone.
