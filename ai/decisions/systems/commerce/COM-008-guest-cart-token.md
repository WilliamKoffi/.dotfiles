---
id: COM-008
title: "A guest cart is keyed by a token, not the session"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# COM-008 — A guest cart is keyed by a token, not the session

## Decision

A guest cart is identified by a random `guest_token` the client keeps and sends; it
does not depend on the server session. At login the guest cart is merged into the
customer's.

## Why

A token works the same for a browser, an SSR server and a JSON client, and survives a
session reset.

## Consequences

- The token is unguessable and unique; it is never an id.
