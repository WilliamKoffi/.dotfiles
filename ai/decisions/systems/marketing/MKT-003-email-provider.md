---
id: MKT-003
title: "Email goes through the mailer; marketing has its own sender"
system: marketing
status: locked
date: 2026-09-27
conflicts: []
requires: [MKT-002]
supersedes: null
---
# MKT-003 — Email goes through the mailer; marketing has its own sender

## Decision

All email goes through the framework's mailer, with the provider set by configuration
(a log mailer in development). Marketing sends from its own subdomain; open and click
tracking is enabled only there, and order email stays untracked. The provider's webhook is
signature-checked before anything is read and rejects every call when the secret is
missing. A hard bounce or a complaint unsubscribes the address. Sends are rate-limited to
the provider's limit and retried with backoff on transport errors only.

## Why

A separate sender protects order email's reputation. A webhook that trusts unsigned
calls lets anyone unsubscribe or fake engagement.

## Consequences

- Opens are shown as indicative (privacy proxies inflate them); clicks are the firmer signal.
