---
id: PST-001
title: "Pest tests in tests/feature and tests/unit, named *.test.php"
system: php/pest
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# PST-001 — Pest tests in tests/feature and tests/unit, named *.test.php

## Decision

Tests are written with Pest. They live in `tests/feature/` and `tests/unit/` (lowercase),
grouped by module in subfolders, and every file is kebab-case ending in `.test.php`:
`tests/feature/orders/place-order.test.php`.

## Why

Lowercase paths and a `.test.php` suffix read the same as the JavaScript tests next to
them, and the suffix separates test files from helpers.

## Consequences

- `phpunit.xml` declares both suites with `suffix=".test.php"`, and `tests/Pest.php` binds the `TestCase` with `->in('feature', 'unit')`.
- A `*Test.php` file or a capitalised test folder is a finding.
