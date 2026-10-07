---
id: RST-013
title: "Tests live in `tests/`, mirroring `src/`, as children of the module they test"
system: rust
status: locked
date: 2026-10-05
conflicts: []
requires: [RST-003, RST-011]
supersedes: null
---
# RST-013 — Tests live in `tests/`, mirroring `src/`, as children of the module they test

## Decision

Every test of a crate lives in its `tests/` folder, in the same tree as `src/`: the tests of
`src/id/ulid.rs` are `tests/id/ulid.rs`. The source file attaches them at its end:

```rust
#[cfg(test)]
#[path = "../../tests/id/ulid.rs"]
mod tests;
```

The test file is then a child module of the code it tests: it sees private items through
`super::`. Each crate sets `autotests = false` in its `Cargo.toml`, so Cargo does not also build
the files of `tests/` as separate crates. No inline `mod tests { … }` in a production file.

## Why

Production files hold production code only, the tests are found at the same path under
`tests/`, and nothing is made `pub` for a test.

## Consequences

- `pub(crate)` never widens an item for a test.
- `#[sqlx::test]` works the same in these modules; `cargo sqlx prepare` runs with
  `-- --all-targets` so their queries are cached.
- `clippy.toml`'s `allow-*-in-tests` covers them: they are `cfg(test)` modules.
