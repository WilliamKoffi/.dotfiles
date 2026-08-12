---
name: drift
description: Wave 8 of the refactor pipeline. Verifies the invariants of every wave and places the files created along the way. Makes no new decision.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Bash(git mv *), Bash(git status *)
---

# Wave 8 — drift

Mission: **verify, and bring into conformance what waves 2 to 5 created.**

This is the only wave allowed to revisit wave 1's category — and only for
**conformance**, never re-decision. You apply the existing convention to files
that never met it. You do not change the convention.

## Allowed perimeter

- conformance moves and renames on files created after wave 1
- updating the ledger

## Frozen

- all semantics
- the convention itself

## Verification

For each family present, run the `## drift` section of its rulebook in
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

Then check the pipeline invariants listed in `rules/families.md`:

- `src/legacy/` intact
- one commit per wave
- no modification outside the scope

## Report

- Findings closed, by wave
- Remaining open findings, with their owning wave
- Open `kind: "defect"` findings — count, and the rule number of each
- Written exemptions, with their justification
- Files brought into conformance here
- State of the build, the typecheck and the tests

## Exit gate

The ledger is empty, or every remaining finding carries a written and justified
exemption. No finding stays open without a decision.

`kind: "defect"` is the one status that is neither closed nor exempt and still
passes the gate: no wave is permitted to act on it (`crud.md` §C9.1, §C9.5).
Report its count and rule numbers as a gate line of their own. A defect merely
left `deferred`, with no count surfaced here, is indistinguishable from a
finding someone forgot — surfacing it is the whole mechanism that keeps it from
being silently dropped.
