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

## Output

`convention.md` §7.6 governs. Your files: `waves/split.json`, the `waves.split`
key of the manifest, `events.jsonl` (open and close, `decision` plane),
`coverage.json`, `concerns/`, `stale` markers, and findings **raised** on
another wave's shard per §7.2.

Write `disposition` on every finding you close. Never append it to `note`.
`created[]` for every file you wrote — from that moment the name is frozen
against `lexicon` and `drift` (`convention.md` §7.5).

**You cut files apart, so you re-anchor.** §7.6 binds you exactly as it binds
`slice`: after your last cut, sweep every shard for findings whose `path` names
a file you split, and rewrite it to whichever half now holds the symbol the
finding is about. Where the finding spans both halves, point `path` at the one
holding the declaration and say so in `disposition`. Set `"stale": true` only
where no half is the right answer.

Check your own shard's paths before you start, for the same reason: wave 1 moved
files after your shard was written.

**Extraction has a red line.** The "extract inline SVGs to `assets/`" rule must
never be pointed at an untouchable zone — a generated-but-committed registry, a
vendored asset tree, a template family whose inline styling is deliberate.
`survey` records those zones; read them before extracting anything.

## Exit gate

- No file above the threshold without a written exemption
- Every created file conforms to its family's convention
- No import cycle introduced
- Test suite green with no test modified, or the clause recorded as
  **unsatisfiable** naming the missing runner (`convention.md` §5.1)
- `split` findings closed or justified, each with a `disposition`
- **Zero stale `path` in any shard** after your cuts
- No file created inside an untouchable zone
- No finding closed on the grounds that its `path` does not exist
- Open and close events written to `events.jsonl`
- No file under `trash/grain/` written outside §7.6's table
- No middleware declaration outside the root routes file — `php.md ## split`
- No `routes/` decomposition performed while a `C9.2` finding is open
