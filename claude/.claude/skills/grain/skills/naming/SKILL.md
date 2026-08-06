---
name: naming
description: >
  Standalone naming pass — props, attributes, variables, and filenames judged
  against shared/convention.md §2. Runs outside the wave pipeline and needs no
  ledger. Do NOT use for method placement (use affordance), for identifier
  renaming inside a pipeline run (use lexicon), or for file relocation
  (use slice).
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Grep, Glob, Edit
argument-hint: "[chemin]"
---

# naming — standalone

Mission: **names only.** No file moves, no method moves, no structural edits.

This skill is not a wave. It reads no ledger, writes no ledger, and closes no
findings. It exists so a naming pass can be run on a folder without committing
to the full pipeline.

## Required reading

Read `${CLAUDE_PLUGIN_ROOT}/shared/convention.md` §2 in full before renaming
anything — one-word props (2.1), the escape hatch (2.2), `set*` scope (2.3),
variables (2.4), filenames (2.5).

Read the family rulebook for the stack under
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`. Where a rulebook and §2 disagree, §0
precedence decides.

## Write scope

| Path | Access |
|------|--------|
| Identifiers within the scope path | edit |
| Call sites of any identifier renamed here | edit |
| Filenames | read — renaming files belongs to `slice` |
| `trash/ledger.json` | never |

If a name is wrong because the concept is wrong, stop. A misnamed thing that is
also the wrong thing is `domain`'s finding, not this skill's. Report it and
leave the name alone.

## Procedure

1. Glob the scope path. Read each file.
2. For each identifier, judge it against §2. A name that already complies is
   not a finding — do not pad.
3. Rename, then update every call site in the same edit pass. Grep the repo for
   the old name before moving on; an incomplete sweep is a broken build.
4. Preserve behavior exactly — see §5. A rename that would collide with an
   existing name is reported, not forced.

## Checkpoint warning

This skill may be invoked in a forked context. Fork-applied changes fall outside
session checkpoints and cannot be rewound with `/rewind`. Commit before running
it on a scope you care about.

## Reporting

| File | Old → new | Rule | Call sites updated |
|------|-----------|------|-------------------:|

Close with one line naming anything left alone and why — collisions, deferrals
to `domain`, and `exempt:readability` calls per §9.
