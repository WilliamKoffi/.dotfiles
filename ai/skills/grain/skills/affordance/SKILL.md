---
name: affordance
description: Wave 4 of the refactor pipeline. Moves behavior to the object holding the state and removes agent nouns. Renames no file.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Wave 4 — affordance

Mission: **behavior lives on the object holding the state.**

## Allowed perimeter

- placement of methods and functions
- membership in a class, an impl, a module, a namespace
- removal of agent noun classes
- affected call sites

## Frozen

- file paths and names
- type definitions created in wave 2
- literal unions extracted in wave 3
- props and presentation state (wave 5)
- identifier names (wave 7)
- runtime behavior

## Rules

The `## affordance` section of each family's rulebook, in
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

Common principle: move the method to the object holding the state, not to the one
performing the action.

## Entity or namespace

Wave 2 decided **that a name was missing**. You decide **what kind of thing it
is**:

- it keeps state between two calls -> entity
- it does not -> namespace, module, or free function

Never create an empty object to group stateless functions. Every target language
already has a grouping mechanism: use its own.

## Output

`convention.md` §7.6 governs. Your files: `waves/affordance.json`, the
`waves.affordance` key of the manifest, `events.jsonl` (open and close,
`decision` plane), `coverage.json`, `concerns/`, `stale` markers, and findings
**raised** on another wave's shard per §7.2.

Write `disposition` on every finding you close. Never append it to `note`.

**Check your shard's paths before you start.** A finding whose `path` is absent
from disk is `blocked:stale`, never silently closed — wave 1 moves files and
your shard was written before it ran (§7.6, "Re-anchoring"). Hunt for the
destination or block the finding; do not close work that was correctly
identified and merely mislocated.

## Exit gate

- Zero agent noun class or struct in scope
- No method whose body mainly mutates another object
- Test suite green with no test modified, or the clause recorded as
  **unsatisfiable** naming the missing runner (`convention.md` §5.1) — this
  wave moves methods between objects, which is the class of change a typecheck
  is least able to vindicate, so the line matters here more than anywhere
- `affordance` findings closed or justified, each with a `disposition`
- No finding closed on the grounds that its `path` does not exist
- Open and close events written to `events.jsonl`
- No file under `trash/grain/` written outside §7.6's table
