---
name: drift
description: Wave 8 of the refactor pipeline. Verifies the invariants of every wave and places the files created along the way. Makes no new decision.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write(trash/grain/roots/*/events.jsonl), Write(trash/grain/roots/*/concerns/**), Bash(git mv *), Bash(git status *), Bash(git ls-files:*), Bash(git log *)
---

# Wave 8 — drift

Mission: **verify, and bring into conformance what waves 2 to 5 created.**

This is the only wave allowed to revisit wave 1's category — and only for
**conformance**, never re-decision. You apply the existing convention to files
that never met it. You do not change the convention.

## Allowed perimeter

- conformance moves and renames on files created after wave 1
- the `waves.drift` key of the manifest, and `rename_pending[]` resolution

You are the only wave that opens every file under
`trash/grain/roots/<root>/` — every shard, the manifest, `plan.json` and
`coverage.json`. That breadth is the mission: the partition that keeps waves 1–7
honest also means nobody but you can see the run whole. You read all of it and
mutate no finding's status.

You operate on **one root's ledger at a time** (`convention.md` §7.0). Two roots
are two runs, reported separately; there is no cross-root reconciliation because
there is no cross-root `F-` sequence to reconcile.

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
- every finding carries a `path` (`convention.md` §7.2), and every `path`
  resolves on disk or the finding carries `"stale": true`
- every finding not `open` carries a `disposition`, and no `note` was
  overwritten by a closing wave
- every finding whose `raised_by` is not `survey` carries `status: "open"` at
  the moment it was raised, and its id sits below the manifest's
  `id_high_water`

**The stale-path sweep.** Run it across every shard; it is the cheapest check in
this file and it catches the failure with the longest fuse:

    for w in trash/grain/roots/<root>/waves/*.json; do
      jq -r '.findings[] | select(.path != null and .stale != true)
             | "\(.id) \(.path)"' "$w"
    done | while read -r id p; do [ -f "$p" ] || echo "STALE $id $p"; done

Every line is a wave that moved a file and did not re-anchor (`convention.md`
§7.6). Report them as unmet, naming the moving wave where `touched[]` or
`created[]` identifies it.

A finding carrying `path: null` is a **different** failure — a schema violation,
not a stale coordinate. Report the two separately; conflated, the second inflates
the first and a reader concludes the ledger is more broken than it is.

**`blocked` is not `skipped`.** `convention.md` §8 makes a *skipped* wave a
normal outcome you must **not** report as an unmet invariant. `blocked` is its
opposite: the wave could not run because a `required` tool was absent, and you
**must** report it as unmet, quoting the manifest's `reason` string and pointing
at `trash/grain/remedy.sh`. The two statuses read as adjacent and are opposite —
conflate them and you silence exactly the failures worth surfacing.

**A quarantined binary is not a finding.** It is a differential failure
between two implementations of one algorithm — it is not a claim about the
user's code, it closes nothing and opens nothing, and it must not enter
`coverage.json`. Report it as a gate line and only a gate line.

## The outcome plane

You are the wave that writes `outcome` events (`observe.md` §2.2). No wave can
observe its own reception, and you are the last one standing.

For every artifact a wave in this run created or touched, determine which of
four things happened and append one event carrying the **producing** run's id
in `subject_run` and your own in the envelope:

| `kind` | Determined by |
|---|---|
| `accepted` | the file exists, unmodified since the wave wrote it |
| `edited` | it exists and its blob SHA differs from the one recorded at creation |
| `rerun` | the same wave ran again against an overlapping scope before you did |
| `reverted` | `git log` shows the commit undone inside `window_days` |

`reverted` is the one you frequently cannot answer in this run: a revert three
days from now is invisible today. Write it when `git log` already shows it,
and leave the artifact unresolved otherwise — a **later** `drift` on the same
root resolves it. Do not write `accepted` as a default for "no revert seen
yet". That single substitution would make the outcome plane report near-total
acceptance forever, which is both wrong and the most flattering possible
error — the reason to name it here rather than trust it not to happen.

Every event states its own `window_days` (`observe.md` §2.2). You write these
events and you close no finding by doing it; an outcome is a fact about the
world's response, not a decision this wave is permitted to make.

**Digest every path** (`observe.md` §4). The report you print names files in
plaintext for the human reading it; the events do not.

## Report

- Findings closed, by shard
- Remaining open findings, with their owning wave **and their `kind`** — and,
  separately, the count of open findings whose `kind` their owning wave does not
  fire on. That second number is the one no other line in this report contains:
  a wave reporting "skipped, nothing to do" and a wave reporting "3 closed" look
  identical whether or not open work is stranded beside them in the same file.
  Name the wave, the `kind`, and the id of each.
- **Concerns reconciliation** — for every note under `concerns/` claiming to
  hand work to another wave, the finding id it raised (`convention.md` §8f).
  A note that names no id is reported as unmet: the receiving wave reads its
  shard, not this directory, and the work will not happen. Report also any note
  whose named finding does not exist.
- Coverage entries by `kind`, `out-of-perimeter` counted separately from misses.
  The first is waves holding their perimeter and recording what they saw — a
  healthy number, not a fault. The second is a detector gap.
- **Plan reconciliation** — per entry: built, overruled, stale, or untouched.
  An entry left untouched by a closed wave is the report's most useful line: it
  is work the run intended and did not do, already written in the form a human
  needs to finish it by hand.
- `defer_to` findings, by target wave — these are the next `survey`'s input, not
  this run's backlog
- Open `kind: "defect"` findings — count, and the rule number of each
- Written exemptions, with their justification
- Waves with status `blocked`, with their `reason` — reported as unmet
- Files brought into conformance here
- State of the build, the typecheck and the tests. Where `capability.json`
  reports no test runner for a family, the line reads **unsatisfiable**, naming
  the missing runner, and lists every wave that recorded it the same way
  (`convention.md` §5.1). It never reads green. No wave in this suite observes
  behaviour without a runner, and the whole of §5 is a behavioural claim — a
  green line here is the run overstating its own evidence base at the exact
  point a reader is deciding whether to trust it.
- Stale-path sweep: count of stale `path` values by shard, and count of findings
  carrying `path: null`, reported separately
- Forge gate: the engine used this run (`python` | `nim` | `none`), and
  whether `trash/grain/forge/forge.json` records a quarantine
- Resolver gate: the resolver per root (`capability.json.roots[].resolver`),
  and the count of graph edges by `resolution` tier. A run whose edges are
  wholly `heuristic` states so in one line — `observe.md` §9.3 makes that the
  difference between a pipeline that can rename across files and one that
  cannot, and it is invisible in every other line of this report.
  Report alongside it the count of findings resting on an **unverified consumer
  count** — a threshold decision taken over heuristic edges, permitted by
  `observe.md` §9.3.1 and required to say so. These are the run's softest
  conclusions and they read exactly like its firmest ones everywhere else.
- Renames deferred `blocked:unresolved`, counted separately from
  `blocked:out-of-scope`. The two read alike and have opposite remedies: one
  needs a wider scope, the other needs a language server.
- Record gate: total events by plane, and any `seq` discontinuity. A gap means
  a wave died between incrementing and appending, and the run is missing
  evidence exactly where it was going wrong.
- Store gate: whether `trash/grain/store/objects/` exists. It must not
  (`observe.md` §6). Its presence is a doctrine violation, reported as unmet.

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

**A `defect` describing work an owning wave would fire on fails the gate.**
`convention.md` §7.5 reserves the kind for what no wave owns. Misfiled work
inherits the one exemption in this file and becomes permanently invisible —
which is the mechanism by which a rulebook's outright ban on a construct can sit
open through an entire pipeline run and be reported as compliant throughout.
Report each such finding by id and name the wave that should have received it.

The stale-path sweep and the concerns reconciliation are gate lines too: a stale
`path` fails the gate, and a concerns note handing work to a wave without naming
a finding id fails it. Both are unfinished handoffs, and both are silent
everywhere else.
