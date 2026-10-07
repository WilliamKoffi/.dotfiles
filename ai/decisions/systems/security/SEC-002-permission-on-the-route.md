---
id: SEC-002
title: "A permission is declared on the route and checked before the handler runs"
system: security
status: locked
date: 2026-10-07
conflicts: []
requires: []
supersedes: null
---
# SEC-002 — A permission is declared on the route and checked before the handler runs

## Decision

Each route declares the permission it requires, next to its definition:

```php
#[Requires(Permission::TeamInvite)]
public function invite(…) { … }
```

```rust
.route("/team/invite", post(invite).layer(Requires::new(Permission::TeamInvite)))
```

One middleware resolves the caller's effective permissions and refuses the request before the
handler runs. A rule that depends on the target row (the last administrator cannot be removed,
only a subordinate role can be changed) is not a route permission: it lives in the module, next
to the write it guards.

## Why

The permission of every endpoint is read where the endpoint is declared, and a handler never
starts work it is not allowed to finish.

## Consequences

- A test lists the routes that declare no permission; each one must be public on purpose.
- Permissions are an enum, never free strings.
