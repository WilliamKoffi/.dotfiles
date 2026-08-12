---
name: slice
description: Wave 1 of the refactor pipeline. Places every file in its slice and applies its family's naming convention. Touches no logic.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(git mv *), Bash(git status *)
---

# Wave 1 — slice

Mission: **every file in the right place, under the right name.**

## Allowed perimeter

- file paths and names
- directory creation
- import and export lines affected by a move
- PSR-4 mapping, `.nimble` file, module declarations

## Frozen

- all logic, all signatures, all symbol identifiers
- every file outside `$scope`
- `src/legacy/`

## Rules

The convention depends on the family. Read the `## slice` section of the
rulebook matching each file's extension, in
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

**Never generalize one family's convention to another.** The dot separator is an
ecmascript rule; it breaks Blade, Rust and Nim.

If a file has an extension with no rulebook: do not touch it.

## Method

1. One family at a time, one commit per family.
2. Always move with `git mv`, to preserve history.
3. After each batch, update the references — including the string ones the
   compiler will not see: view calls, service container, configuration, class
   references by name.
4. Build after each batch, not only at the end.

## Exit gate

- Build green, typecheck green
- No broken reference, including string references
- No pure re-export file left
- Zero dead imports
- `slice` findings in the ledger closed or justified
