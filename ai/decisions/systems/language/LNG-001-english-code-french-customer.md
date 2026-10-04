---
id: LNG-001
title: "English everywhere except text the customer reads, in French"
system: language
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# LNG-001 — English everywhere except text the customer reads, in French

## Decision

Code, comments, commits, docs, tasks and decisions are in English. Text the customer
reads (pages, e-mails, validation messages, admin labels the client uses) is in French.

## Why

Code and tooling are English-first; the customers read French.

## Consequences

- A French identifier in code is a finding.
- An English string shown to a customer is a finding.
