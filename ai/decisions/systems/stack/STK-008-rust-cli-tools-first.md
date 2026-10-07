---
id: STK-008
title: "Shell work uses the Rust CLI alternatives first"
system: stack
status: locked
date: 2026-10-07
conflicts: []
requires: []
supersedes: null
---
# STK-008 — Shell work uses the Rust CLI alternatives first

## Decision

When a shell command is needed, by a person, an agent, a script or a task check, the Rust
alternative is used first:

| Instead of | Use |
| --- | --- |
| `grep -rn` | `rg` |
| `find` | `fd` |
| `sed 's/…/…/'` | `sd` |
| `cat` (to read) | `bat` |
| `ls` | `eza` |
| `diff` | `delta` |
| `cloc` / `wc -l` over a tree | `tokei` |
| a structural code search | `ast-grep` |

The classic tool is used only when the Rust one is missing on the machine or lacks the feature
needed, and the command says why. `cat` stays fine inside a pipe or a heredoc.

## Why

The Rust tools are faster on a large tree, respect `.gitignore`, and behave the same on every
platform, where the classic tools differ between GNU and BSD.

## Consequences

- Commands written in agent roles, tasks and docs use `rg`, `fd` and the others.
- A machine without them (CI, a fresh container) installs them, or falls back as allowed above.
