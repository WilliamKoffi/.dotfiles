---
name: lexicon
description: Wave 7 of the refactor pipeline. Renames identifiers per each family's rulebook. Changes nothing else.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Wave 7 — lexicon

Mission: **rename. Nothing else.**

Renaming comes last because it touches every call site and only makes sense once
placement, shape and ownership are frozen. This wave's diff must read as a pure
rename.

## Allowed perimeter

- identifier names only: variables, parameters, properties, props, methods,
  functions, types

## Frozen

- absolutely everything else: paths, file names, structure, types, ownership,
  props as a surface, behavior
- every path listed in a closed finding's `created[]`, in any shard: those names
  were just set by doctrine in this same run, and renaming them here is an undo
  in flight. The paths in `rename_pending[]` belong to `drift`, not to you.

**A name in `plan.json` is not frozen.** The plan is `survey`'s proposal; only
`created[]` records a decision actually taken. A plan entry whose finding is
still `open` names a file nobody built, and if that file exists under that name
anyway, it predates the run and is ordinary scope. Reading the plan to decide
what to skip would freeze names on the strength of a suggestion.

Read `created[]` across every shard for this — it is the one cross-shard read
in the suite, and it is a read of decisions already taken, never of open work.

## Rules

The `## lexicon` section of each family's rulebook, in
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

If the section is absent for an extension, the file is out of perimeter.

**Case and prefix rules diverge sharply between families.** The `is` predicate
prefix is forbidden in ecmascript and idiomatic in PHP, Rust and Nim. Never apply
one family's rule to another.

## Method

One rename at a time, across the whole scope, verified, then the next. A batch of
simultaneous renames makes the conflict undetectable.

## Exit gate

- Zero prefix forbidden by the family concerned
- Zero memory-structure or metadata suffix
- No new abbreviation
- Build green, typecheck green
- Test suite green, with no test modified
- `lexicon` findings closed or justified
