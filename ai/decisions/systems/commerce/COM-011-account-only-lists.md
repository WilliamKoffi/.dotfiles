---
id: COM-011
title: "Wishlist and comparison are stored only for accounts"
system: commerce
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# COM-011 — Wishlist and comparison are stored only for accounts

## Decision

Wishlist and comparison rows require a customer, and their API routes require
authentication. Guests keep these lists in the browser (`localStorage`), synced to the
account after login. No anonymous rows are written.

## Why

Anonymous list rows fill the database with data no one comes back for, and need their
own expiry.

## Consequences

- The login flow merges the browser lists into the account, then clears them.
