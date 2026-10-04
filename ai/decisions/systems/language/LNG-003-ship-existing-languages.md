---
id: LNG-003
title: "Ship only the languages the content exists in"
system: language
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# LNG-003 — Ship only the languages the content exists in

## Decision

A product launches in the languages its real content is written in. Copy is never
invented or machine-filled to add a language. Adding one later is translation rows and an
admin tab, not a schema change.

## Why

Invented copy is wrong copy, and it ships as if it were approved.

## Consequences

- Translatable columns go through one translations mechanism from the start, even with one locale.
