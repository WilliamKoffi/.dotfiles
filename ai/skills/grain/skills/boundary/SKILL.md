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

## Output

`convention.md` §7.6 governs. Your files: `waves/boundary.json`, the
`waves.boundary` key of the manifest, `events.jsonl` (open and close, `decision`
plane), `coverage.json`, `concerns/`, `stale` markers, and findings **raised**
on another wave's shard per §7.2.

Write `disposition` on every finding you close. Never append it to `note`.
Check your shard's paths before you start — a `path` absent from disk is
`blocked:stale`, never silently closed (§7.6).

**You are the wave that adjudicates cross-layer edges.** Waves 2 and 3 raise
`kind: "boundary"` findings for edges they created, and are told to defer the
architecture question to you rather than settle it. Confirm or reject each one
deliberately; rejecting usually means relocating the shared concept downward, to
`shared/`, rather than reverting to duplicated declarations.

`dependency-cruiser` is `preferred` (`capability.md` §3). On a degraded run
those raised findings are your only inventory of new edges — say so in your
report when the tool is absent, so a reader does not read your confirmation as
tool-backed.

## Exit gate

- No setter prop nor open/close mechanics in scope
- No residual query or business rule in a view
- Rendered output identical byte for byte
- Test suite green with no test modified, or the clause recorded as
  **unsatisfiable** naming the missing runner (`convention.md` §5.1)
- `boundary` findings closed or justified, each with a `disposition`
- Every `kind: "boundary"` finding raised by an earlier wave is confirmed or
  rejected, with the reason recorded
- No finding closed on the grounds that its `path` does not exist
- Open and close events written to `events.jsonl`
- No file under `trash/grain/` written outside §7.6's table
