---
name: cruddy
description: >
  Reshapes Laravel/PHP controllers and routes to resource-only actions per
  shared/crud.md. Fires between `domain` and `affordance`, and only when the
  ledger's stack is laravel or php. Do NOT use for domain object design
  (use affordance) or for identifier renaming (use lexicon or naming).
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Grep, Glob, Edit, Write
argument-hint: "[chemin]"
---

# Wave [cruddy] — CRUDdy by design

Mission: **every routed action is one of the seven resourceful verbs.**

This wave is the same principle as `affordance` applied to a framework's
routing layer. It is not a peer of `affordance` and does not replace it — it
mutates different files (routes and controllers, not domain objects) and fires
on one stack only.

## Required reading

Read `${CLAUDE_PLUGIN_ROOT}/shared/crud.md` in full before acting. It is
authoritative for the seven actions, resource naming, pivots, state changes,
single-action controllers, and route declaration style.

Read `${CLAUDE_PLUGIN_ROOT}/shared/convention.md` §5 (behavior preservation),
§6 (the legacy red line), and §7 (the ledger) before the first edit.

Do not restate either file's rules here. Cite them by section — `§C4`, `§5`.

## Applicability gate — run this first

1. Read `trash/grain/roots/<root>/ledger.json` — the manifest, `convention.md` §7.1.
2. If the file does not exist, stop: *"No ledger. Run `/grain:survey` first."*
3. If `stack` is neither `laravel` nor `php`, set `waves.cruddy.status` to
   `"skipped"` and exit without opening a shard or a source file.
4. If `waves/cruddy.json` is absent, set `waves.cruddy.status` to `"skipped"`
   and exit. An absent shard is the skip signal — §7 has `survey` write no shard
   for a wave with no findings.
5. Open `waves/cruddy.json`. If no **open** finding carries a `rule` starting
   with `C`, set `"skipped"` and exit.

You open two files at this wave's start and never a third: the manifest and your
own shard. `waves/domain.json` is not yours to read, and a `defer_to: "cruddy"`
sitting in it belongs to the next `survey`, not to this run.

`rule` is the routing key; `wave` is derived from it. §C0 reads the rule
prefix, so a finding carrying `wave: "cruddy"` without a `C`-prefixed `rule`
would skip this wave silently — and a skipped wave is a normal outcome `drift`
is told not to report, so the failure would never surface. Where the two
disagree, `rule` wins.

The gate exists so the pipeline stays linear. Every other wave can assume it
runs unconditionally; only this one checks.

## Write scope

| Path | Access |
|------|--------|
| Controllers named in open `cruddy` findings | edit / create |
| `routes/*.php` | edit |
| Call sites of routes this wave changes — named-route helpers in `app/`, `routes/` | edit |
| `trash/grain/roots/<root>/waves/cruddy.json` | edit — your own findings |
| `trash/grain/roots/<root>/ledger.json` | edit — the `waves.cruddy` key, nothing else |
| `trash/grain/roots/<root>/plan.json` | edit — `stale` only, on entries whose `from[]` you touched |
| `trash/grain/roots/<root>/events.jsonl` | append — open and close, `decision` plane (§7.6) |
| `trash/grain/roots/<root>/coverage.json` | append (§7.4) |
| `trash/grain/roots/<root>/concerns/` | create (§8f) |
| `trash/grain/roots/<root>/waves/*.json` (any other) | append a **raised** finding, or set `stale` — never mutate one (§7.2) |
| Domain objects, models beyond `getRouteKeyName()` | read |
| Everything else | read |

A controller absent from the ledger is out of scope even when it is obviously
wrong. It belongs to the next `survey`.

Views and tests are **not** editable here — §C10 forbids the first outright,
and every exit gate in the suite forbids the second. The narrowing is not a
restriction on the wave's reach: under §C9.8 condition 1 the route name is
preserved, so `route()` call sites stay correct untouched, and under condition
2 there are no literals left to update. A grant that could only fire when the
precondition failed is a bypass around §C9.8, not a capability.

Any finding that would require reshaping a domain object rather than a
controller gets `status: "deferred"` and a `defer_to: "affordance"` field. It is
reported, never acted on.

## The plan

A finding carrying `plan_id` points at an entry in `trash/grain/roots/<root>/plan.json`:
the controller, its actions, its URI and its route name, as `survey` derived
them. Read it before applying §C7 — for a `mechanical` entry the answer §C7
would give you is already written down.

**A plan entry is a proposal, not an instruction.** Three dispositions, and you
record which one in the finding's `note`:

| Entry state | You |
|---|---|
| `mechanical`, `stale: false` | adopt `path`, `class`, `actions[]`, `uri` verbatim |
| `judged` | answer its `question` by §C5 or §C7, then fill the entry |
| `stale: true` | re-derive from source. The target was computed against a file an earlier wave has since rewritten. |

Overruling a `mechanical` entry is permitted and must be written down: the
entry's name, yours, and the rule that forced the change. An unexplained
divergence between plan and diff is indistinguishable from a wave that never
read the plan.

`rewritable` is `survey`'s pre-evaluation of §C9.8 conditions 2 and 3 only.
`"false"` is binding — defer. `"unknown"` means condition 1 is still yours to
evaluate, not that the path is clear.

## Procedure — per finding, in ID order

1. Read the target controller.
2. Read the finding's plan entry, if it has one.
3. Apply the §C7 decision tree to the offending action — or confirm the
   `mechanical` entry already applies it.
4. Create the resource controller §C2.1 names, if it does not yet exist.
5. Move the action body across verbatim, renaming it to the resourceful verb.
6. Pair the inverse where one exists — `subscribe`/`unsubscribe` become
   `@store`/`@destroy` on one controller, not two. Two findings sharing a
   `plan_id` are one controller — build it once.
7. Update `routes/` — drop the custom route, add `Route::resource` or an
   `only([...])` subset, spelled per §C9 so `lexicon` finds nothing to fix.
8. Update the call sites inside the write scope: named-route helpers and
   `action()` calls in `app/` and `routes/`. A call site in a view or a test is
   `blocked:out-of-scope` — record it, do not edit it.
9. Set that finding's `status` to `closed`, list every file you wrote in its
   `created[]`, and write the shard.

Write the shard after every finding, never once at the end. An interrupted run
must leave an accurate map behind — and with the plan alongside it, an
interrupted run leaves a human the remaining work in full.

`created[]` is what freezes a name: from that write, `lexicon` and `drift` skip
the file. A controller built from a plan entry but absent from `created[]` will
be renamed by wave 7, undoing doctrine mid-run.

## Behavior preservation

The rewrite moves code. It does not change what the code does — see §5.

- Authorization, validation, and side effects transfer verbatim.
- Response shape and status codes stay identical unless the finding's note
  explicitly says otherwise.
- If preserving behavior is impossible, leave the finding `open`, append a
  `blocked_reason`, and continue. Report blocked findings at the end.

## Reporting

Per §C12, then close with counts of `closed`, `deferred`, and `blocked`, and
one line stating the ledger persists for a resumed run.
