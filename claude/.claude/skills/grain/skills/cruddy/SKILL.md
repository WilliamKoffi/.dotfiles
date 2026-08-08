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

1. Read `trash/grain/ledger.json` at the repo root.
2. If the file does not exist, stop: *"No ledger. Run `/grain:survey` first."*
3. If `stack` is neither `laravel` nor `php`, write `"cruddy": "skipped"` to the
   ledger and exit without reading any source file.
4. If `stack` matches but no finding has `wave: "cruddy"` and `status: "open"`,
   write `"cruddy": "skipped"` and exit.

The gate exists so the pipeline stays linear. Every other wave can assume it
runs unconditionally; only this one checks.

## Write scope

| Path | Access |
|------|--------|
| Controllers named in open `cruddy` findings | edit / create |
| `routes/*.php` | edit |
| Call sites of routes this wave changes — views, tests, JS | edit |
| `trash/grain/ledger.json` | edit — `status` of `cruddy` findings only |
| Domain objects, models beyond `getRouteKeyName()` | read |
| Everything else | read |

A controller absent from the ledger is out of scope even when it is obviously
wrong. It belongs to the next `survey`.

Any finding that would require reshaping a domain object rather than a
controller gets `status: "deferred"` and a `defer_to: "affordance"` field. It is
reported, never acted on.

## Procedure — per finding, in ID order

1. Read the target controller.
2. Apply the §C7 decision tree to the offending action.
3. Create the resource controller §C2.1 names, if it does not yet exist.
4. Move the action body across verbatim, renaming it to the resourceful verb.
5. Pair the inverse where one exists — `subscribe`/`unsubscribe` become
   `@store`/`@destroy` on one controller, not two.
6. Update `routes/` — drop the custom route, add `Route::resource` or an
   `only([...])` subset, spelled per §C9 so `lexicon` finds nothing to fix.
7. Update every call site: named-route helpers, `action()`, form targets,
   redirects, tests.
8. Set that finding's `status` to `closed` and write the ledger.

Write the ledger after every finding, never once at the end. An interrupted run
must leave an accurate map behind.

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
