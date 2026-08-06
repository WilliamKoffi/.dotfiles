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

## Exit gate

- Zero agent noun class or struct in scope
- No method whose body mainly mutates another object
- Test suite green, with no test modified
- `affordance` findings closed or justified
