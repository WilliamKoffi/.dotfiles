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
- **declarations themselves** — de-export a symbol with no external consumer;
  never delete the declaration. A symbol dead everywhere and not merely dead
  externally is `drift`'s to remove, and the doctrinal move is to raise a
  finding on its shard (`convention.md` §7.2, "Raising"), not to remove it in
  passing. Deleting is a source edit of a different kind from moving a file, and
  an edit outside the perimeter is invisible to the gate meant to check it.
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
5. After the last batch, **re-anchor** — see below.

## Re-anchoring — this wave's second mission

`convention.md` §7.6 binds every wave that invalidates a path. It binds you
hardest: your entire perimeter is paths, so you are the only wave that can
invalidate every other shard at once.

Before your close event, sweep **every** shard — not only your own — for
findings whose `path` names a file you moved, renamed or deleted this run.
Rewrite `path` to the new location; set `"stale": true` where the file is gone.
Change nothing else about those findings.

    for w in <every wave>.json; do
      jq -r '.findings[] | select(.path != null) | "\(.id) \(.path)"' "$w"
    done | while read -r id p; do [ -f "$p" ] || echo "STALE $id $p"; done

Run it and expect zero lines. A wave that opens its shard three waves from now,
finds the file missing and closes the finding as stale is the failure this
prevents — correctly identified work disappearing while every count in the run
still reconciles.

Line coordinates you cannot repair, so do not create the problem: a coordinate
belongs in `sites[].range`, never in `note` prose.

## Output

`convention.md` §7.6 governs. Your files: `waves/slice.json`, the `waves.slice`
key of the manifest, `events.jsonl` (open and close, `decision` plane),
`coverage.json`, `concerns/`, and `stale` markers per §7.6.

Write `disposition` on every finding you close — never append the answer to
`note`. `created[]` for files you wrote, `touched[]` for files you edited.

A file you would move if it were in the ledger, but is not, is out of perimeter
and belongs in `coverage.json` as `kind: "out-of-perimeter"` — a folder whose
role is unrecognized, a sibling that would be dragged along by a rename. Not
acting on it is correct; not recording it is what loses it (§7.4).

## Exit gate

- Build green, typecheck green
- No broken reference, including string references
- No pure re-export file left
- Zero dead imports
- **Zero stale `path` in any shard** — the sweep above returns nothing
- No declaration deleted
- `slice` findings in the ledger closed or justified, each with a `disposition`
- Open and close events written to `events.jsonl`
- Test suite green with no test modified, or the clause recorded as
  **unsatisfiable** naming the missing runner (`convention.md` §5.1)
- No file under `trash/grain/` written outside §7.6's table
