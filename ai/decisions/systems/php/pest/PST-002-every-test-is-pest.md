---
id: PST-002
title: "Every test is written in Pest; no PHPUnit test class is left"
system: php/pest
status: locked
date: 2026-10-07
conflicts: []
requires: []
supersedes: null
---
# PST-002 — Every test is written in Pest; no PHPUnit test class is left

## Decision

Every test is a Pest function, `test('…', function () { … })` or `it(…)`. A test file binds its
base case with `uses(...)` or `pest()->extend(...)`:

```php
uses(IntegrationTestCase::class);

test('login refuses a wrong password', function () {
    // …
});
```

The abstract base test cases stay classes; nothing else does. A codebase moving to Pest converts
every existing test, with the same number of tests and assertions before and after.

## Why

One style across the suite: a reader never switches between a class and a function form, and a
new test copies whatever test sits next to it.

## Consequences

- A `class … extends TestCase` holding test methods is a finding.
- A conversion tool (such as `pest-plugin-drift`) is used for the conversion only, then removed.
