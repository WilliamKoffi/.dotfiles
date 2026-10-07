---
id: RST-016
title: "Every function lives on a type; a namespace is a zero-sized struct"
system: rust
status: locked
date: 2026-10-07
conflicts: []
requires: [RST-015]
supersedes: null
---
# RST-016 — Every function lives on a type; a namespace is a zero-sized struct

## Decision

No free function: every `fn` is a method or an associated function of a type. When the function
acts on no value of its own, the type is a zero-sized struct that names the group:

```rust
pub struct Reject;

impl Reject {
    pub fn unreadable() -> Error {
        Refusal::new(
            StatusCode::UNPROCESSABLE_ENTITY,
            "body.unreadable",
            "The body of the request could not be read.",
        )
        .into()
    }

    pub fn invalid() -> Error {
        Refusal::new(StatusCode::UNAUTHORIZED, "session.invalid", "Log in again.").into()
    }
}
```

The call site reads `Reject::unreadable()`, never `unreadable()`.

Four exceptions stay free functions:

- `fn main`;
- test functions (`#[test]`, `#[tokio::test]`, `#[sqlx::test]`), which the harness calls by name;
- a function a framework demands as a free function: a handler or a middleware passed by path
  (`get(login::open)`, `from_fn(guard)`), a `serde` `with` helper, code a macro generates;
- a private helper used by functions of the same file only (`fn hex(bytes: &[u8]) -> String`).

## Why

The type names the context at every call site (`Reject::invalid()`, `Ulid::new()`), related
functions stay together in one `impl`, and RST-015's "behaviour belongs to the noun" then holds for
the functions that have no value to act on. There is no runtime cost: a zero-sized struct is gone
after compilation.

## Consequences

- A public free function that fits none of the four exceptions is a finding.
- A group of error constructors is one zero-sized struct (`Reject`); a group of builders, of
  queries or of checks likewise takes the noun they build, read or check.
- The exceptions are kept small: a handler calls the slice's types, it holds no logic of its own
  (AXM-001).
