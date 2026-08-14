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
- the `waves.drift` key of the manifest, and `rename_pending[]` resolution

You are the only wave that opens every file under `trash/grain/` — every shard,
the manifest, `plan.json` and `coverage.json`. That breadth is the mission: the
partition that keeps waves 1–7 honest also means nobody but you can see the run
whole. You read all of it and mutate no finding's status.

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

Then the ledger's own integrity, which sharding makes checkable rather than
assumed:

- every shard named in `manifest.shards` exists, and every shard on disk is
  named in the manifest
- no finding sits in a shard other than its owning wave's
- every `plan_id` on a finding resolves to a plan entry, and every plan entry
  has at least one finding pointing at it
- every `F-` and `P-` id is unique across all shards
- a wave whose manifest status is `"closed"` has no `open` finding left in its
  shard

## Report

- Findings closed, by shard
- Remaining open findings, with their owning wave
- **Plan reconciliation** — per entry: built, overruled, stale, or untouched.
  An entry left untouched by a closed wave is the report's most useful line: it
  is work the run intended and did not do, already written in the form a human
  needs to finish it by hand.
- `defer_to` findings, by target wave — these are the next `survey`'s input, not
  this run's backlog
- Open `kind: "defect"` findings — count, and the rule number of each
- Written exemptions, with their justification
- Files brought into conformance here
- State of the build, the typecheck and the tests

## Exit gate

Every shard is empty of `open` findings, or every remaining one carries a
written and justified exemption. No finding stays open without a decision.

The plan is reconciled: every entry is built, overruled with a reason, or
reported unbuilt. An unbuilt entry does not fail the gate — a plan is a
proposal — but an unreported one does.

`kind: "defect"` is the one status that is neither closed nor exempt and still
passes the gate: no wave is permitted to act on it (`crud.md` §C9.1, §C9.5).
Report its count and rule numbers as a gate line of their own. A defect merely
left `deferred`, with no count surfaced here, is indistinguishable from a
finding someone forgot — surfacing it is the whole mechanism that keeps it from
being silently dropped.
