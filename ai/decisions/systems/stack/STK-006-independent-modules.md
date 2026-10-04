---
id: STK-006
title: "Modules never compose each other's pages"
system: stack
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# STK-006 — Modules never compose each other's pages

## Decision

A module does not import another module to build a screen. Each exposes its own
resources, and the client composes a page from separate calls (banners from content,
featured products from the catalogue). There is no composite endpoint such as `/home`.

## Why

A composite endpoint makes one module depend on every module its page shows, and grows
with each new block.

## Consequences

- A new cross-module import is justified in the module map, or removed.
