---
id: NXT-002
title: "Nuxt renders in the browser only (SPA)"
system: ts/nuxt
status: locked
date: 2026-09-27
conflicts: [NXT-001]
requires: []
supersedes: null
---
# NXT-002 — Nuxt renders in the browser only (SPA)

## Decision

The Nuxt app runs with `ssr: false`: it is served as a static shell and renders in the
browser.

## Why

A back-office or logged-in app gains nothing from server rendering, and dropping it
removes every hydration mismatch.

## Consequences

- Pages are not indexed with their content; public pages that need search engines choose NXT-001.
