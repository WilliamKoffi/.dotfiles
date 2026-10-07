---
id: RST-015
title: "Behaviour belongs to the noun it acts on"
system: rust
status: locked
date: 2026-10-05
conflicts: []
requires: [RST-006]
supersedes: null
---
# RST-015 — Behaviour belongs to the noun it acts on

## Decision

An action is a method of the object that affords it, not a free function that takes that
object as its first argument. On a type of another crate, the method comes from an extension
trait named by the one word of what it extends, with no suffix (`Pool` for `PgPool`,
`Connection` for `PgConnection`; never `PoolExt` or `PoolAffordance`). What an action needs is a
noun built first and handed over: `pool.claim(Claim::tenant(id).by(user))`, not
`Tenancy::tenant(id).begin(pool)`.

## Why

The call reads as a sentence (subject, verb, object), and a function that takes its object as
first argument is a manager class in disguise.

## Consequences

- No `Manager`, `Helper`, `Service` or `Utils` type.
- A trait method that returns a future is declared `fn … -> impl Future<Output = …> + Send` and
  implemented with `async fn`; `+ Send` is left out only when a caller's closure cannot be
  `Send` (`visit` takes an `AsyncFnOnce`).
