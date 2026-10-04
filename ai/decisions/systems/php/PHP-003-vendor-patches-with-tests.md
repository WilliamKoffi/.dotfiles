---
id: PHP-003
title: "A vendor patch ships with its tests"
system: php
status: locked
date: 2026-09-28
conflicts: []
requires: []
supersedes: null
---
# PHP-003 — A vendor patch ships with its tests

## Decision

A change to a Composer dependency is a patch applied by `cweagans/composer-patches`, kept in
`api/patches/<vendor>/<patch>/` with three files:

- `src.patch` — the source change, declared under `extra.patches` in `api/composer.json`;
- `tests.patch` — the tests, written in the dependency's own test layout;
- `README.md` — the exact version patched, the purpose, and the upstream PR link once opened.

A patch without its `tests.patch` is not declared in `composer.json`.

## Why

The two diffs together form an upstream pull request as they stand, and the tests catch a
patch that stops applying or stops working on a version bump.

## Consequences

- Two files, because published packages usually exclude `tests/` (`export-ignore`), so tests
  cannot be applied inside `vendor/`.
- CI clones the dependency at the pinned tag, applies both patches and runs its test suite.
- The patched package is pinned to an exact version; every bump reruns that job.
- `patches/` is a folder, not a PHP namespace.
