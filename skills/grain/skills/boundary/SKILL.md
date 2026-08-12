---
name: boundary
description: Wave 5 of the refactor pipeline. Internalizes presentation state, compresses the prop surface, and extracts logic out of views. Splits no file.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Wave 5 — boundary

Mission: **business state stays outside, presentation state moves inside.**

Applies only to families whose rulebook has a `## boundary` section: ecmascript
components and Blade views. A pure module has neither props nor presentation
state — skip it.

## Allowed perimeter

- a component's prop surface
- internal hooks or presentation objects
- parent-side wiring affected by the compression
- extracting logic out of views, toward the entity or a dedicated presentation
  object

## Frozen

- file paths and names
- type definitions (wave 2)
- literal unions extracted in wave 3
- placement of domain methods (wave 4)
- file splitting (wave 6)
- identifier names (wave 7)

## Rules

The `## boundary` section of each family's rulebook, in
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

## Mandatory sequence

In this order, no exception:

    detect the repeated primitives
      -> use the name or union already extracted in waves 2 and 3
      -> reduce the number of props
      -> internalize the interaction state

Splitting does not belong to this wave. A component still large after
compression will be handled in wave 6 — and it will often have shrunk on its
own.

## Signals

- a `setX`, `showX`, `openX`, `toggleX` prop
- an open/close pair crossing a boundary
- more than three callbacks in props
- more than two booleans in props
- a query, business rule, or network call inside a view

## Exit gate

- No setter prop nor open/close mechanics in scope
- No residual query or business rule in a view
- Rendered output identical byte for byte
- Test suite green, with no test modified
- `boundary` findings closed or justified
