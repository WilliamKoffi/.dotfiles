---
id: RST-002
title: "Crate packages and folders are kebab-case"
system: rust
status: locked
date: 2026-10-04
conflicts: []
requires: []
supersedes: null
---
# RST-002 — Crate packages and folders are kebab-case

## Decision

Folders and Cargo package names are kebab-case (`shop-sales`), seen in code as snake_case
(`shop_sales`).

## Why

Cargo and crates.io use kebab-case; one spelling on disk avoids guessing.

## Consequences

- File names inside a crate stay snake_case, as `rustc` requires for modules.
