---
id: OPS-001
title: "Every process is supervised behind one TLS proxy"
system: ops
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# OPS-001 — Every process is supervised behind one TLS proxy

## Decision

In production each app runs as its own supervised process (for example PHP-FPM for the
API, Node for the SSR front end). A TLS-terminating reverse proxy is the only public entry;
forwarded headers are trusted only from configured proxy addresses, and requests only for
configured hosts. A supervised queue worker and a scheduler run every minute are required
processes, and workers restart after each release is activated.

## Why

Unsupervised processes die silently; workers that are not restarted run the previous
release's code.

## Consequences

- A deploy script that does not restart workers is a finding.
- No host, domain or certificate is chosen in the repository; these are operator inputs.
