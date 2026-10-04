---
id: MKT-005
title: "Visitor statistics are first-party and consent-gated"
system: marketing
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# MKT-005 — Visitor statistics are first-party and consent-gated

## Decision

Page views are counted by the app itself, only for visitors who accepted analytics;
Do-Not-Track and Global Privacy Control are honoured. The visitor id is a hash of app
secret, day, IP and user agent, so it rotates daily; the IP is never stored. Country and
city are resolved locally (CDN headers or a local geo database), never by a third-party
call. Paths with secrets are cut to their first segment, robots and admin are not counted,
and old rows are pruned.

## Why

Owning the numbers avoids a third-party tracker, and storing nothing identifying keeps
them lawful.

## Consequences

- The statistics page says the figures cover consenting visitors only.
