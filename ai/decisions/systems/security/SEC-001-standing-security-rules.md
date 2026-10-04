---
id: SEC-001
title: "Standing security rules"
system: security
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# SEC-001 — Standing security rules

## Decision

- A file path from a request is resolved with `realpath` and must stay under its base
  folder; `..`, `\` and null bytes are rejected.
- Anything guessable (coupon codes, references) is throttled; user-supplied quantities are
  capped.
- Every app sends security headers (frame-ancestors, `nosniff`, `Referrer-Policy`,
  `Permissions-Policy`, HSTS over HTTPS).
- A new admin page is administrator-only until a policy says otherwise.
- An order reference is not a credential: paying or claiming for a guest order needs a
  capability token returned once at placement.
- Internal links from rich text may not start with `//` or `/\`.

## Why

Each rule closes a class of bug seen in a real audit; stated once, they are checked on
every new surface.

## Consequences

- Each rule has a test that guards it.
