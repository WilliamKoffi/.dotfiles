---
id: SUP-001
title: "Post-sale support is its own module"
system: support
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# SUP-001 — Post-sale support is its own module

## Decision

Authenticated, post-sale conversations are a support module, separate from the public
contact form. A ticket belongs to a customer and may reference their order or return.
Category and priority are enums; lifecycle (assigned, resolved, closed) is timestamps, and
reopening is an explicit action. Customers see and reply only to their own tickets. Staff
may add internal notes, which the customer API never serializes.

## Why

Mixing pre-sale leads and post-sale tickets loses the order context and exposes
internal notes.

## Consequences

- A closed ticket rejects new replies.
