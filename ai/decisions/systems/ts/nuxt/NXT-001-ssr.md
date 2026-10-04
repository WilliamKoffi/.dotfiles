---
id: NXT-001
title: "Nuxt renders on the server (SSR)"
system: ts/nuxt
status: locked
date: 2026-09-27
conflicts: [NXT-002]
requires: []
supersedes: null
---
# NXT-001 — Nuxt renders on the server (SSR)

## Decision

The Nuxt app renders universally (`ssr: true`). Every browser-only library loads from a
`plugins/*.client.ts` file, and markup whose first render depends on `window`,
`localStorage` or a random value is wrapped in `<ClientOnly>`.

## Why

Pages that must be indexed and paint fast need real HTML from the server.

## Consequences

- A `window` reference outside a `.client` file is a server error, not a warning.
- The API base URL has one key in `runtimeConfig`; a second key is added only when the server needs a different host.
