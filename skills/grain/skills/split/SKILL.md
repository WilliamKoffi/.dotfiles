---
name: split
description: Wave 6 of the refactor pipeline. Splits what is still too large, at the boundaries that survived compression. Renames no identifier.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(git mv *), Bash(git status *)
---

# Wave 6 — split

Mission: **split what stayed large, where the responsibility changes.**

This wave comes late **by construction**. Waves 2 to 4 removed the plumbing;
many files that were over the threshold are already back within it. Splitting
earlier would have produced bad cuts.

## Allowed perimeter

- splitting one file into several
- creating composers
- extracting graphic assets
- imports affected by a split

## Frozen

- prop surface and ownership (wave 5)
- type definitions (wave 2)
- literal unions extracted in wave 3
- placement of domain methods (wave 4)
- identifier names (wave 7)
- runtime behavior

## Rules

The `## split` section of each family's rulebook, in
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

**The 150-line threshold is a trigger for review, never an order to cut.** A
180-line file that does one coherent thing stays whole: record a written
exemption in the ledger and move on.

Split only on a real responsibility boundary.

## Placement constraint

Every file created here follows wave 1's naming convention for its family.
Consult the `## slice` section of the rulebook — you re-decide nothing.

## Exit gate

- No file above the threshold without a written exemption
- Every created file conforms to its family's convention
- No import cycle introduced
- Test suite green, with no test modified
- `split` findings closed or justified
- No middleware declaration outside the root routes file — `php.md ## split`
- No `routes/` decomposition performed while a `C9.2` finding is open
