---
id: OPS-004
title: "Logs go to stderr or daily files, chosen by config"
system: ops
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# OPS-004 — Logs go to stderr or daily files, chosen by config

## Decision

Application logs are written to stderr (for the process supervisor to collect) or to
daily rotating files, chosen by configuration. Every other process's output goes to its
supervisor. No log provider is chosen in the repository.

## Why

Where logs end up depends on the host; the app only has to make both paths work.

## Consequences

- A hard-coded log destination or a provider SDK in the app is a finding.
