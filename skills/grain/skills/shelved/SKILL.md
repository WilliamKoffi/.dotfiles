---
name: shelved
description: >
  Repository / data-access wave of the grain pipeline. Constrains every
  repository to a fixed method vocabulary and pushes all query variation into
  the name of the repository — the persistence counterpart of grain:cruddy.
  Invoked manually as /grain:shelved [chemin] after grain:cruddy has closed.
  Reads open ledger findings of kind `repository` and rewrites data-access
  classes to close them. Do NOT use this for controllers or routing (that is
  grain:cruddy), for domain extraction (grain:domain), for renaming files
  (grain:drift), or as a general "review my code" entry point — this wave
  assumes a ledger written by grain:survey.
disable-model-invocation: true
user-invocable: true
argument-hint: [chemin]
allowed-tools: Read, Glob, Grep, Edit, Write
---

# grain:shelved — Repository Architecture

A repository is a **shelf**. Every shelf in the building supports the same
handful of operations. When you need a different set of things, you do not
invent a new operation — you add a new shelf.

Doctrine, in reading order:

| File | What it holds |
|---|---|
| `../../shared/convention.md` | Naming law, agent-noun ban, behavior preservation, ledger schema, wave order |
| `../../shared/shelf.md` | §S0–§S10 — the repository doctrine itself, language-general |
| `../../shared/rules/<stack>.md` | Stack-specific implementation (Eloquent, Diesel, Prisma…) |
| `references/patterns.md` | Before/after examples |

Read `shared/shelf.md` in full before touching a file. Read the stack ruleset
named by `ledger.stack`. Read `references/patterns.md` when you need an example
of a rewrite you have not performed before.

---

## Gate

Refuse and stop if any of these fail:

1. `trash/grain/ledger.json` — the manifest — exists. If absent → *"Run
   `/grain:survey <chemin>` first."*
2. `waves.cruddy.status` is `"closed"` or `"skipped"`. Controllers are shaped
   before the shelves they call. If `"open"` → *"`/grain:cruddy` is still open.
   Close it first."* You read this from the manifest; you never open
   `waves/cruddy.json` to find out.
3. `stack` is present and its rulebook carries a `## shelves` section. Today
   that is `php` alone — any other stack sets `waves.shelved.status` to
   `"skipped"` and exits, which is a normal outcome, not a failure. If the stack
   has a `## shelves` section but no other rules to apply, use
   `shared/shelf.md` alone and record `stack_ruleset: none` in the wave entry.
4. `trash/grain/waves/shelved.json` exists. If absent, the survey found nothing
   for you: set `"skipped"` and exit.

If invoked with a `[chemin]` argument, narrow to that subtree. If invoked bare,
operate on every path the ledger lists under open `repository` findings.

---

## Write scope

**Owns:** the data-access tree only — files whose class implements or is named
as a repository, DAO, query object, or shelf, plus new shelf classes this wave
creates.

**Never touches:** controllers, HTTP layer, routes, migrations, tests, views,
domain entities. `grain:cruddy` owns the HTTP tree; `grain:domain` owns
entities. If a rewrite here would require a controller edit, do not make it —
leave the finding `open` with `blocked_by: "boundary"` and a one-line note. You
do not create a `boundary` finding: §7 reserves creation to `survey`, and
`waves/boundary.json` is not a file this wave opens.

**Never renames a file.** Creating a new file is in scope; `git mv` is
`grain:drift`'s job. Record every file you create in the closing finding's
`created[]` so `grain:lexicon` and `grain:drift` skip them.

**Ledger scope:** `trash/grain/waves/shelved.json` (your findings), the
`waves.shelved` key of the manifest, and `stale` on `plan.json` entries whose
`from[]` you edited. No other shard, not even to read.

---

## Procedure

### 0. Read the plan

Every `repository` finding with a `plan_id` points at an entry in
`trash/grain/plan.json` naming the shelf to build: its `class`, its `path`, and
the subset of §S1 it exposes in `actions[]`. `survey` derives these
mechanically — `shelf.md` §S3 turns `findActiveUsers()` into `ActiveUsers` by
rule, with no judgment to make.

Adopt a `mechanical` entry verbatim. Re-derive a `stale: true` entry from
source. Overrule either only with the reason written into the finding's `note`.

The plan is not a substitute for §2 below: it names the shelf, it does not
classify the violation. A §S6 builder leak still stops the rewrite whatever the
plan says the new class is called.

### 1. Inventory

Glob the data-access tree. For every class, list its public methods and mark
each one **in-vocabulary** or **out**. The vocabulary is §S1 of `shelf.md`.

Emit the inventory as a table before changing anything:

| Class | Methods | Out of vocabulary | Verdict |
|---|---|---|---|

### 2. Classify each violation

```
Is the method one of the 7?
├── YES → ✅ leave it. Check §S4 (scope), §S5 (ordering), §S6 (builder leak).
└── NO  → ❌ open a finding. Then ask:
          │
          ├── Does it narrow which items?      (findActive, getExpiring…)
          │     → §S3 — noun the filter, new shelf
          │
          ├── Does it narrow which shelf?      (forTeam, ofUser…)
          │     → §S4 — move to the constructor, vocabulary unchanged
          │
          ├── Does it order or limit?          (latest, topTen, sortedBy…)
          │     → §S5 — that is a second shelf, not an argument
          │
          ├── Does it return a builder/queryset/IQueryable?
          │     → §S6 — hard stop, this leak invalidates the whole shelf
          │
          └── Is it genuinely open-ended user-driven search?
                → §S7 — Criteria object, the only sanctioned escape hatch
```

### 3. Rewrite

One class per edit. After each rewrite, verify by reading every call site of
the removed method — a shelf rename with a dangling caller is a broken build,
not a refactor. If a call site lives outside your write scope, revert the
rewrite and open a `boundary` finding instead.

Behavior preservation is absolute: the same rows, in the same order, with the
same laziness. See `convention.md` on the legacy red line.

### 4. Close the ledger

For each finding in `waves/shelved.json`: set `status: "closed"`, list
`created[]` and `touched[]`. Leave anything you could not close as `open` with a
one-line `blocked_by`. Write the shard after each finding, not once at the end.

Then write your key — and only your key — into the manifest:

```json
"shelved": {
  "status": "closed",
  "stack_ruleset": "php",
  "opened": 11,
  "closed": 9,
  "deferred": 2
}
```

A `boundary` finding you open (see write scope) has nowhere to go: `survey` owns
finding creation and `waves/boundary.json` is not yours to write. Record it in
the blocking finding's `note` and report it. The next `survey` raises it.

Never close a finding you did not actually rewrite.

---

## Report format

Per violation, in this order:

1. **🚨 Issue** — the rule number and a four-word name (`§S3 — filter in signature`)
2. **Why it matters** — one sentence on the cost
3. **✅ Shelf** — the new class and its vocabulary
4. **Call sites** — every caller you updated, by path

Never show bad code without the fix immediately after it.

---

## Pragmatism

A shelf per query is right when queries are named concepts of the domain. It is
wrong when a repository is a thin internal seam nobody else calls. If a rewrite
would produce a class used exactly once, by exactly one caller, in exactly one
file — record it as `deferred` with the reason and move on. Doctrine is a
gradient, and this wave is not the last one to run.
