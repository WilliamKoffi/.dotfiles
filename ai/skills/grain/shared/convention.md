# grain — Shared Convention

> Single source of truth for the `grain` skill suite.
> Every skill in `~/.claude/skills/grain/skills/` reads this file.
> **Never restate these rules inside a SKILL.md.** Reference them by section number.

---

## §0. Precedence

When two rules collide, resolve in this order:

| Rank | Rule class | Beats |
|---|---|---|
| 1 | §6 Legacy red line | Everything |
| 2 | §5 Behavior preservation | Everything below |
| 3 | §1 Affordance placement | Naming, file size |
| 4 | §2 Naming | File size |
| 5 | §3 File structure | — |

If a rule cannot be satisfied without breaking a higher-ranked one, record it in
the ledger as `deferred` with a one-line reason. Do not silently drop it.

---

## §1. Affordances over Abilities

### 1.1 — Reject agent nouns
Classes named `Manager`, `Service`, `Handler`, `Broadcaster`, `Sender`,
`Processor`, `Coordinator`, `Helper`, `Util` are middlemen. Flag every one.

The ban is not confined to the service layer. A class that retrieves data is
named for the **set it returns**, never for the act of retrieving it:
`UserFetcher`, `UserFinder`, `UserQuery`, `UserSearchService` are the same
violation wearing a persistence costume — the name is `ActiveUsers`. See
`shelf.md` §S3 for the repository-layer instance of this rule.

Exception: framework-mandated names (`ServiceProvider`, `RequestHandler` from an
interface you do not own). Record as `exempt:framework`.

### 1.2 — Method placement
Move a method to the object **holding the state**, not the object **performing
the action**.

```
❌ gardener.water(plant)      — ability
✅ plant.water()              — affordance
❌ user.redeemLicense(l)      — god object
✅ license.redeem(user)       — affordance
```

**Test:** if the method body mutates `other` more than `this`, it belongs on `other`.

### 1.3 — Missing concepts
A bloated controller/component does not need another Service. It needs a **noun**
— a domain object that owns the state. Extract `Checkout`, `Draft`, `Session`,
not `CheckoutService`.

### 1.4 — Stateless collections
If a module holds no state and only wraps side effects or native calls, it is not
a class. Use a namespace (TS), module (Python/Ruby), or static class (C#/Java).

```ts
export namespace Asset {
  export function ship() { }
}
// Asset.ship()
```

Invocations should read as English: `Asset.ship()`, `Store.read()`, `Invoice.send()`.

---

## §2. Naming

### 2.1 — Props and attributes: one English word

| ❌ | ✅ |
|---|---|
| `isOpen` | `open` |
| `isLoading` | `busy` |
| `handleClose` | `close` |
| `onInput` | `input` |
| `submitAction` | `submit` |
| `hasError` | `broken` / `invalid` |

### 2.2 — The one-word escape hatch
A compound name is permitted **only** when the one-word form is genuinely
ambiguous in that file's scope. Two conditions, both required:

1. The one-word form already means something else in the same scope, **and**
2. No better single word exists in English.

When you use the escape hatch, record `naming:compound` in the ledger with the
collision it avoids. Unrecorded compounds are violations.

### 2.3 — `set*` scope
`setX` is reserved **exclusively** for the setter half of a `[state, setter]`
pair (`useState`, signals, stores).

- Setter: always camelCase — `setReady`, `setOpen`
- A method that mutates without being a reactive setter is **not** `setX`.
  `invoice.setPaid()` → `invoice.pay()`. `door.setOpen()` → `door.open()`.

### 2.4 — Variables
No abbreviations. No acronyms except domain-standard ones (`url`, `id`, `http`).
Underscores only where a language idiom requires them.

### 2.5 — Files
The file name is the concept it exports — `measure.ts` exports measuring, not
`measureUtils.ts`. That principle is the whole of this section.

**The naming scheme itself belongs to the family rulebook**, in the `## slice`
section of `rules/<family>.md`. Each family fixes its own form and its own closed
role list; this file names no scheme and holds no role list. Per §0, a rule
stated in two places drifts, and the rulebook is the one the waves actually read.

---

## §3. File structure

### 3.1 — Size
Max **150 lines**. Over that, split.

### 3.2 — Split by role, not by type
When a file mixes concerns, split into a folder where each file is a **role**:

```
resize/
  measure.ts    ← the ruler
  listen.ts     ← the ear
  animate.ts    ← the mover
  index.ts      ← the composer
```

Not `types.ts` / `utils.ts` / `constants.ts` — those are types, not roles.

### 3.3 — `index` ruling
**`index` is a composer, never a barrel.**

- ✅ `index.ts` assembles the roles in its own folder into the public concept.
- ❌ `index.ts` that only re-exports siblings (`export * from './measure'`).

A folder whose `index` is a pure re-export means the folder was a false split —
collapse it back into one file, or give the index real composition work.

Root-level `src/index.ts` as an entry point is exempt.

---

## §4. Component boundaries

- A component that both fetches and renders has two jobs. Split the fetch upward.
- Props flow down. Events flow up. No prop drilling past two levels — extract
  context or move the state down.
- A component holding more than three pieces of local state is holding a domain
  object it hasn't named yet. See §1.3.

---

## §5. Behavior preservation

Every `grain` skill operates under one rule, uniform across the suite:

> **Observable behavior must not change.** Public API, rendered output, network
> calls, and side-effect ordering are identical before and after.

Consequences, binding on every skill:

- Renames of **exported** symbols require updating all call sites in the same pass.
- If a call site lives outside the argument path, the rename is **deferred**, not
  performed. Record `blocked:out-of-scope` in the ledger.
- If the **set** of call sites is not known to be complete, the rename is
  deferred for that reason instead — `blocked:unresolved`. A partial pass is
  not a permitted outcome of this rule, so an incomplete set is a stop, not a
  best effort. What makes a set complete is `shared/observe.md` §9.3; the test
  is stated there and not here.
- No behavior fixes. If a skill finds a bug, it records it and moves on. A bug
  fix is a separate commit by a human.
- No dependency additions. No config changes. This constrains the user's
  repository, not `trash/`: anything grain builds for its own use under
  `trash/grain/` adds no dependency to any manifest, writes no config file the
  repo will read, and is removed by deleting one gitignored directory.

### 5.1 — An unsatisfiable gate clause is recorded, never skipped

Every mutating wave's exit gate asserts *test suite green, with no test
modified*, and `rules/families.md` makes it a pipeline invariant. Some
repositories have no test runner at all — `capability.md` §3 probes for one per
family and records its absence in `gaps[]`.

Where the clause cannot be evaluated, the wave writes it to the `decision` plane
and to its report as **unsatisfiable**, naming the missing runner. It does not
write it as satisfied, and it does not omit the line.

This is not bookkeeping. A typecheck observes types and a build observes
resolution; neither observes behaviour, and this suite's own §5 is a behavioural
claim. The waves that move methods between objects, cut files apart and rename
across a tree are exactly the ones a typecheck cannot vindicate. A gate line
that silently disappears when it cannot be met turns *we did not check* into *we
checked and it passed*, and the run's evidence base is overstated by precisely
the amount that matters most.

The severity of an absent runner, and why it carries that severity, belong to
`capability.md` §3 ("Test runners") and are not restated here. This section
rules only on what a wave writes when the clause cannot be evaluated.

---

## §6. The legacy red line

Do **not** touch, import from, or modify anything under `src/legacy/`.

Violations found there are recorded as `legacy:observed` and never acted on.
A skill that would need to edit a legacy file to complete a change must defer
the whole change instead.

---

## §7. The ledger

Every skill reads and writes under `trash/grain/`. The ledger is **sharded**:
one manifest, one file per wave, plus two run-level files.

```
trash/grain/
  capability.json          preflight artifact (§8c)
  forge/                   runtime accelerator (§8d)
  store/                   content-addressed cache and symbol graph (§8e)
  salt                     workspace digest salt (§8e). Never transmitted.
  consent.json             upload opt-in. Absent means no (§8e).
  roots/<root>/
    ledger.json            manifest — run facts and wave status. Never findings.
    waves/<wave>.json      findings owned by that wave.
    plan.json              artifacts the pipeline intends to create. Advisory.
    coverage.json          coverage_misses[]. Append-only by any wave.
    events.jsonl           the record — three planes, append-only (§8e).
    saltmap.json           digest → plaintext. Local only (§8e).
    concerns/<slug>.md     judgment calls and degradations, in prose (§8f).
```

`store/`, `salt` and `consent.json` sit **beside** `roots/`, not inside one,
and the asymmetry is deliberate. The ledger is keyed by root because a finding
is a fact about a place (§7.0). The store is keyed by content hash, and a
content hash is the same fact in every root holding those bytes — keying it per
root would store one file's graph twice in a monorepo and give the two copies
no way to agree. Doctrine: `shared/observe.md` §8.2.

`events.jsonl` is per-root because an event names a wave, and a wave runs
against one root.

### 7.0 — Root keying

One ledger per **root**, as detected by `doctor` (`capability.md` §2), never per
scope argument. `<root>` is the root's `path` with `/` replaced by `-`, and `.`
— the repo root — rendered as `root`.

Root, not scope, because scope is arbitrary user input and a root is a doctrinal
fact already computed. A Laravel repo spanning `./{app,modules,resources,routes}`
is **one** root: one `composer.json`, one stack, one rulebook, therefore one
ledger. Two ledgers are for `api/` + `web/` — different stacks, different
rulebooks, no shared `F-` sequence.

This is what makes §7.1's singular `stack` and `families` true again. As written
today they are simply false in any monorepo: one manifest cannot name the stack
of two roots. Root keying is the repair, not a new constraint.

**Cross-root.** No wave reads or writes another root's ledger. The `F-` and `P-`
sequences are per-root, and a finding never references a path outside its own
root. Two roots are two runs that happen to share a session.

`trash/` is a working directory, never committed. Add to the repo's
`.gitignore` before the first survey:

```gitignore
trash/
```

A ledger that reaches a commit is a bug: it records a run, not a decision, and
it will conflict on every branch that touches the same scope. If `trash/` is
already tracked, `git rm -r --cached trash/` before continuing.

The shape is the contract. A wave's two mutable files are
`roots/<root>/ledger.json` and `roots/<root>/waves/<itself>.json`; §7.6 gives
the full table, including the three appends and the two markers that reach
outside it.

Where a wave touches no source file, write scope is enforced by what it holds
open rather than by an instruction telling it to behave, and `survey`'s and
`drift`'s grants are written that way. A mutating wave needs open `Write` and
`Edit` for the repository itself, so for it the ledger scope survives only as
prose — §7.6 states it once and every mutating exit gate re-asserts it. Per §0
that is the weaker arrangement, and it is the reason the assertion appears in
the gate rather than the commentary.

### 7.1 — The manifest

```json
{
  "root": "api",
  "stack": "laravel",
  "scopes": ["app/Http", "modules"],
  "families": ["php"],
  "id_high_water": { "F": 42, "P": 11 },
  "shards": ["slice", "domain", "cruddy", "shelved", "affordance",
             "boundary", "split", "lexicon"],
  "waves": {
    "survey": { "status": "closed", "findings": 42, "plan_entries": 11 },
    "slice":  { "status": "open" },
    "cruddy": { "status": "skipped" },
    "split":  { "status": "blocked", "reason": "tsc absent" }
  }
}
```

Every later wave rewrites exactly one key — `waves.<itself>` — and touches no
other. Run facts (`root`, `stack`, `scopes`, `families`) are stated here and
nowhere else; a shard that restates `stack` is a second source of truth and a
defect.

**`scopes[]` accumulates.** A second `survey` against a non-overlapping scope
within the same root appends and merges rather than clobbering. This resolves a
contradiction: `survey/SKILL.md` says "create or update the four files" while
this section previously said `survey` writes the manifest whole, once. Both
cannot hold. The merge rule governs — the whole-write case is now just the
degenerate one where no ledger exists yet. `survey` refuses an overlapping
scope outright rather than merging it (`survey/SKILL.md`, Output).

**`id_high_water` persists the counters.** "Never reuse a retired id" was stated
but nothing carried the number: a second survey would have to rescan every shard
plus `plan.json` to recover the maximum. The high-water mark is authoritative
and monotonic. `survey` raises it before writing the manifest and never lowers
it, whatever ids were subsequently retired.

`status` is `open` | `closed` | `skipped` | `blocked`. A gate that must know
whether an earlier wave ran reads this file and stops — `shelved` checking
`waves.cruddy.status` never opens `waves/cruddy.json`.

**`blocked`** carries a sibling `reason` string. It means the wave cannot run
because a tool marked `required` for it is absent per `capability.json.gaps[]`.
Distinguish it sharply from `skipped`: §8 makes being skipped a normal outcome
that `drift` must **not** report as unmet, whereas `blocked` **is** an unmet
invariant and `drift` must report it. It is written by `survey` from
`capability.json`, never by the blocked wave itself — that wave never runs.

### 7.2 — A wave shard

```json
{
  "wave": "cruddy",
  "findings": [
    {
      "id": "F-014",
      "rule": "C2",
      "family": "php",
      "kind": "route-file",
      "path": "app/Http/Controllers/PodcastController.php",
      "note": "subscribe/unsubscribe are custom actions",
      "plan_id": "P-003",
      "status": "open",
      "raised_by": "survey",
      "closed_by": null,
      "disposition": null,
      "source": "grain",
      "confidence": "heuristic"
    }
  ]
}
```

**Status values:** `open` → `closed` | `deferred` | `blocked` | `exempt`

**`path` is mandatory on every finding**, whatever else the finding carries. A
`kind` with a richer location field — `literal-cluster`'s `home`, §7.3's
`from[]` — sets `path` to the same value alongside it. The richer field stays
authoritative for the wave that consumes it; `path` exists so that one query
answers *what does this run say about this file* across every shard. A finding
that omits it is invisible to every path-keyed sweep in the suite, including the
staleness check below, and its absence reads as `null` — indistinguishable from
a stale path that resolved to nothing.

**Optional fields**, written by the wave that closes a finding and read by later
waves: `created[]` lists files the wave wrote — `lexicon` and `drift` skip them,
because a name set by doctrine this run must not be re-decided in the same run.
`touched[]` lists files it edited. `rename_pending[]` hands a legacy filename to
`drift` without doing a `git mv`. `plan_id` points at the artifact in
`plan.json` this finding is closed by building. `skipped_sites[]` lists the
sites inside a finding's own perimeter that the wave did not apply, each with a
reason — a finding closed with a non-empty `skipped_sites[]` is closed as to its
decision and incomplete as to its application, and only the field says so.

**`note` states the problem; `disposition` states the answer.** `note` is
written by whoever raised the finding and is **never** overwritten or appended
to by the wave that closes it. The closing wave writes `disposition`: one or two
sentences on what it actually did, or on why it did nothing.

Both fields are needed and neither substitutes for the other. Fold the answer
into `note` and every query that reads `note` as a problem statement gets a
mixed record; leave it out entirely and the ledger reports the wave as having
resolved nothing. The word `resolution` is deliberately **not** used here: §9.1
of `shared/observe.md` reserves it for a graph edge's axis, and a field name
serving two axes is the drift §0 forbids.

**`stale`** is set on a finding by any wave that moves, renames or deletes the
file its `path` names — see §7.6, "Re-anchoring". It is the finding-level twin
of §7.3's `stale` on a plan entry, and it is written under the same licence.

**Cross-shard deferral.** A finding carrying `defer_to: "<wave>"` stays in the
deferring wave's shard with `status: "deferred"`. The named wave does **not**
act on it this run — it is the next `survey`'s input.

**No wave mutates a finding in another wave's shard.** That is the invariant,
and it is about *conclusions*: nobody edits, closes, re-opens, re-kinds or
re-notes work another wave owns. Three writes are permitted outside a wave's own
shard, and all three are appends or markers that decide nothing:

| Write | Where | §  |
|---|---|---|
| `stale` on a plan entry whose `from[]` you edited | `plan.json` | §7.3 |
| `stale` on a finding whose `path` you moved or deleted | any shard | §7.6 |
| a **new** finding with `raised_by: <itself>`, `status: "open"` | any shard | below |

Sharding makes this rule load-bearing rather than polite. In one flat file a
misrouted write was merely untidy; here it is a wave reaching into a document it
never opened.

**Raising.** Any wave may append a new finding to another wave's shard. It sets
`raised_by` to its own name, `status: "open"`, and `closed_by: null`, and it
allocates the id from the manifest's `id_high_water` (§7.1), which it raises in
the same write. It touches no finding already in that shard, and it never
closes, exempts or answers what it raised — a wave that could both raise and
close on another shard would be deciding that wave's work for it.

This is the only channel a mid-pipeline discovery has. Without it, a wave that
notices real work outside its perimeter has exactly two options — act on it,
widening its own blast radius past the gate that was meant to check it, or write
it in prose that the owning wave never reads. Both are worse than a fourth line
in a JSON array. The rule this replaces read *only `survey` creates findings*,
which was already false of `domain` (`domain/SKILL.md`, "Repeated literals") and
which `raised_by` had no purpose under.

`survey` keeps one thing the others do not: it alone creates **plan entries**,
and it alone may raise a finding without having been in the file.

**The `kind` must be one the owning wave fires on.** A finding is routed by
`kind`, not by which shard it sits in, and a shard is not a queue a wave drains
— it is a set of shapes the wave knows how to consume. Filing work under a
`kind` its owning wave does not fire on puts it somewhere it will never be read
and reports it as routed.

`defect` is the sharp case, and §7.5 rules on it below.

**Provenance.** Every finding carries two further fields, stating what produced
it and how far it may be trusted:

| Field | Type | Values |
|---|---|---|
| `source` | string | `knip` · `phpstan` · `ast-grep` · `ctags` · `grain` |
| `confidence` | string | `proven` (tool-derived) · `heuristic` (grain inference) |

A finding with `source: "grain"` MUST carry `confidence: "heuristic"`. A finding
with any tool `source` MUST carry `confidence: "proven"` and MUST NOT be
re-verified by a later wave — bypassing that re-verification is where the
runtime saving comes from. A wave that re-derives a `proven` finding pays twice
for an answer a tool already gave.

`source` MUST be `grain`, or the `name` of a tool marked evidence-producing in
`shared/capability.md` §3. The vocabulary is closed, and it is closed *there* —
this section names no tools of its own, so there is no second list to keep in
sync. A tool that verifies or transforms rather than asserts — a linter gate, a
type-checker, a mutator — is not evidence-producing and never appears as a
`source`.

An extension does not earn its own token. Larastan and
`shipmonk/dead-code-detector` arrive in one PHPStan run and are sourced
`phpstan`; splitting them would fragment one tool's output across three tokens.

**The tool must have asserted the finding, not merely supplied the bytes.**
Knip says *this export is unused*, grain records it: `source: "knip"`,
`confidence: "proven"`. ctags supplies symbol ranges and fan-in counts and grain
concludes *hub-in-leaf*: `source: "grain"`, `confidence: "heuristic"` — the
index holds no opinion about hubs. Attribute the claim to whoever made it. Get
this backwards and a heuristic inference inherits `proven`'s exemption from
re-verification, which is the one thing that tier exists to grant.

**A grain-forged binary can never launder provenance.** A helper binary that
`grain` itself compiled is `grain`. Findings built on its output carry
`source: "grain"` and `confidence: "heuristic"`, permanently — however
deterministic the helper is and however much faster than a hand pass.

`source` draws its closed vocabulary from tools marked evidence-producing in
`capability.md` §3, and a binary `grain` authored is not and cannot be in that
list. Without this rule there is a trivial promotion path: write a script, run
it, attribute your own inference to it, and inherit `proven`'s exemption from
re-verification — the one thing that tier exists to grant.

This is the ctags precedent again: ctags is `required` and Ev `no` because it
indexes without asserting. The forge helper stands in exactly the same
relation to the finding — it computes fan-in, `grain` concludes hub-in-leaf.
See `shared/forge.md` for the mechanism.

**`source` is shared with the plan; `confidence` is not.** §7.3 gives plan
entries a `source` too, and deliberately so: both answer *what authority stands
behind this record*, a finding citing a tool and a plan entry citing a doctrine
section. One concept, two domains, no ambiguity.

`confidence` is finding-only. The plan's neighbouring field is
`determination` — a different axis, named apart on purpose. See §7.3.

There is now a third axis, `resolution`, on symbol-graph edges, named apart on
the same reasoning. It is defined once in `shared/observe.md` §9 and is not
restated here. A finding never carries `resolution` and an edge never carries
`confidence`.

**Emitted shape is authoritative.** The JSON above is illustrative. The field
vocabulary a run actually uses is the one in `survey/SKILL.md`'s output block.
Where the two differ, the emitted shape wins, and a wave must not rewrite
existing entries to match this example.

### 7.3 — `plan.json`

The findings say what is wrong. The plan says what to build. This separation is
the point: a run that exhausts its budget at wave 2 still leaves a human a
complete, readable list of the files the pipeline was going to create.

```json
{
  "plan": [
    {
      "id": "P-003",
      "from": ["app/Http/Controllers/PodcastController.php@subscribe",
               "app/Http/Controllers/PodcastController.php@unsubscribe"],
      "rule": "C2.1",
      "kind": "controller",
      "path": "app/Http/Controllers/SubscriptionController.php",
      "class": "SubscriptionController",
      "actions": ["store", "destroy"],
      "uri": "podcasts/{podcast}/subscriptions",
      "route_name": "podcasts.subscriptions",
      "determination": "mechanical",
      "source": "crud.md §C2.1",
      "rewritable": "unknown",
      "stale": false
    }
  ]
}
```

| Field | Holds |
|---|---|
| `id` | `P-` prefix, its own sequence, never reused |
| `from[]` | the sites this artifact absorbs — `path@symbol` where a symbol is meant |
| `kind` | `controller`, `shelf`, `model`, `migration`, `module`, `home` |
| `path` | the file to create, repo-relative |
| `class` | the exported symbol, where the family has one |
| `actions[]` | the methods it will carry — the seven of `crud.md` §C1, or of `shelf.md` §S1 |
| `uri` / `route_name` | HTTP artifacts only |
| `determination` | `mechanical` \| `judged` |
| `source` | the doctrine section that produced the entry |
| `rewritable` | §C9.8 pre-evaluation, URI entries only |
| `stale` | set by any wave that edits a path in `from[]` |

**Shape here, status there.** A plan entry carries no `status`, and a finding
never restates a target. Duplicating either into the other is the drift §0
forbids.

**A plan entry is a proposal, not a decision.** The executing wave either adopts
it verbatim or overrules it, recording the reason in the finding's `note`. Only
`created[]` freezes a name (§7.5). Until then `lexicon` is free to re-decide it,
because until then nothing was decided.

**`determination`** has exactly two values. It reports how completely doctrine
specifies the target — not how likely the entry is to be true. That is why it is
not called `confidence`: a `judged` entry is not a weak claim, it is an
unfinished one, carrying `null` fields and a `question` awaiting a ruling.
Finding-level `confidence` (§7.2) is the epistemic axis and does not appear on
plan entries.

| Value | Meaning |
|---|---|
| `mechanical` | derivable from doctrine by rule, without judging intent — `findActiveUsers` → `ActiveUsers`, `POST /orders/store` → `/orders`, a nested pair → `{Parent}{Child}Controller` |
| `judged` | requires a branch decision — `crud.md` §C5 A-vs-B, §C7 relation-vs-state, §C9.7 spelling. `path`, `class` and `uri` are `null`, and `question` states what must be decided |

`survey` emits `mechanical` entries in full and `judged` entries as questions.
It never guesses a branch in order to fill a field. A confidently wrong target
is worse than an absent one: absent invites a decision, wrong invites adoption.

**`rewritable`** reports `crud.md` §C9.8 and applies to URI entries only.
`survey` may evaluate conditions 2 and 3 — the literal-URL grep and the
external-binding test — and writes `"false"` when either fails, `"unknown"`
otherwise. It never writes `"true"`: condition 1 belongs to the wave doing the
rewrite.

**Staleness.** A wave that edits a path listed in some entry's `from[]` sets
`"stale": true` on that entry and writes no other field of `plan.json`. This is
the one write any wave makes outside its own shard. An executing wave must
re-derive a stale entry from source rather than adopt it — the target was
computed against a file that no longer reads the way it did at wave 0.

### 7.4 — `coverage.json`

```json
{
  "coverage_misses": [
    {
      "symbol": "getProductById",
      "path": "src/features/catalog/product.query.ts",
      "extension": ".ts",
      "wave": "affordance",
      "kind": "missing-selector",
      "why_missed": "survey enumerated exports only; no symbol inventory ran"
    }
  ]
}
```

A wave appends an entry whenever it **acts on** a symbol no finding covers, or
**observes** an in-family signal it is not permitted to act on. `drift` reports
the total and the per-extension breakdown as a gate line.

The second half is the one that gets forgotten, and it is the more valuable of
the two. A wave holding its perimeter correctly — declining to touch a literal
three lines outside its recorded `range`, declining to rename a folder whose
other occupants are not in the ledger — is behaving exactly as designed, and the
signal it saw dies with the run unless it lands here. The perimeter is what a
wave may *change*; it was never what a wave may *notice*.

Entries of that second kind carry `kind: "out-of-perimeter"` and a `why_missed`
naming the rule that stopped the wave. They are not failures and `drift` does
not report them as unmet — they are the next `survey`'s input, in the one file
that is neither a shard nor prose.

An entry here is not a substitute for raising a finding (§7.2) where the work
has an owning wave and a `kind` that wave fires on. Record what has no home;
raise what has one.

This file is the **one named exception** to the contract below: it is
append-only by any wave, authored by whichever wave found the gap. It closes
nothing and it opens nothing — `findings[]` remains survey-only. Giving it its
own file rather than a key inside a shard is deliberate: an entry authored by
`split` about a gap in `affordance` belongs to neither shard.

Its purpose is arithmetic. A miss noticed once is an anecdote; nine misses
sharing an extension are a defect. Scattered across per-wave report objects they
never add up, which is how a detector gap survives an entire pipeline run.

### 7.5 — Contract

- Only `survey` creates plan entries. Any wave may **raise** a finding on any
  shard, under §7.2's three conditions; only `survey` may raise one without
  having been in the file.
- A wave mutates its own shard and the manifest key bearing its own name. Its
  writes elsewhere are the three in §7.2's table and nothing else.
- No wave closes, edits, or reads-to-mutate a finding in another wave's shard.
  Appending one is not mutating one.
- `drift` reads every shard, the manifest, the plan and the coverage file; it
  mutates no status.
- A wave whose shard holds zero open findings **of a `kind` it fires on** writes
  `"status": "skipped"` to the manifest and exits without opening a source file
  — and names, in its report, every open finding it left behind and the `kind`
  each carries. Being on the shard is not the same as being routed, and a wave
  that reports "nothing to do" while open findings sit in its own file is
  telling the truth in the most misleading available form.
- **`defect` means no wave owns it.** It is for a correctness bug a human must
  fix (`crud.md` §C9.1, §C9.5) — never for work that has an owning wave and a
  `kind` that wave fires on. A wave that meets a `defect` describing work it
  would fire on if re-shaped does not act on it and does not re-kind it in
  place: it raises a correctly-shaped finding per §7.2 and cross-references the
  `defect`, which stays for `drift` to count. `defect` is the one kind that
  passes `drift`'s exit gate unclosed, which makes it the one kind that silently
  absorbs anything filed into it by mistake.
- A wave that builds a plan entry lists the file in the closing finding's
  `created[]`. From that moment the name is frozen against `lexicon` and
  `drift`.
- A wave reads and writes only under `trash/grain/roots/<its own root>/`.
  Cross-root reads are forbidden; two roots are two runs that happen to share a
  session.
- A wave whose manifest status is `blocked` does not run and writes nothing.
  `survey` set that status; the wave never opens to contest it.
- No wave writes to `trash/grain/forge/`. The forge is `survey`'s, per §8d.
- Every wave appends to `roots/<root>/events.jsonl` and may append to
  `roots/<root>/coverage.json` and `roots/<root>/concerns/`. These are the
  general write-scope exceptions in this list; §8e licenses the first, §7.4 the
  second, §8f the third. All three are append-only and none decides anything.
- `store/graph/` is `survey`'s alone. `store/objects/` and `store/index/` are
  written by any wave, and only once `observe.md` §6.1's gate is satisfied —
  until then no wave creates `store/` at all.
- No wave transmits anything. `observe.md` §11.

### 7.6 — Closing a finding

Every wave in §8 follows this section. It is stated once here and referenced
from each `SKILL.md`, because a ledger protocol restated nine times is a ledger
protocol with nine dialects — which is what §0 exists to prevent, and what
happened while this section did not exist.

**Open exactly these.** Nothing else in `trash/grain/` is yours:

| File | Access |
|---|---|
| `roots/<root>/waves/<itself>.json` | edit — your own findings |
| `roots/<root>/ledger.json` | edit — the `waves.<itself>` key, and `id_high_water` when you raise |
| `roots/<root>/events.jsonl` | append |
| `roots/<root>/coverage.json` | append (§7.4) |
| `roots/<root>/concerns/` | create (§8f) |
| `roots/<root>/plan.json` | edit — `stale` only |
| `roots/<root>/waves/*.json` (any other) | append a raised finding, or set `stale` — never mutate |

**Where the grant can carry this, it does.** A wave that is read-only as to code
— `survey`, `drift` — enumerates these paths in `allowed-tools` and holds
nothing wider, so the tool layer enforces the table and no instruction has to.

A mutating wave cannot. It creates and edits source files across the repository,
so its `Write` and `Edit` grants are necessarily open, and an open grant covers
`trash/grain/` too. For those waves this table is the constraint the tool layer
does **not** hold, which is exactly why it is stated once here rather than nine
times, and why each mutating wave's exit gate asserts it: *no file under
`trash/grain/` written outside the table above.* Treat it as tighter than the
grant, not looser — the grant is wide because source editing needs it, not
because the ledger is open.

**Two events, minimum.** Append to the `decision` plane (`observe.md` §2) as you
go, never batched at the end:

- **On open** — the wave name, the scope, the run id, the fingerprint, the
  findings you retained and the ones you did not, and every gate outcome
  including the ones that passed.
- **On close** — counts by final status, the exit-gate results, and one entry
  per gate clause you could not evaluate (§5).

A wave that mutates source and logs neither leaves the manifest asserting a
result nothing corroborates. `ledger.json` says a wave closed twenty-five
findings; only the record says a wave ran.

**Write the closing fields.** `status`, `closed_by: <itself>`, `disposition`
(§7.2) on every finding you touch — plus `created[]`, `touched[]`,
`skipped_sites[]` where they apply. Never write `note`.

**Re-anchoring.** *A wave that invalidates a path repairs the shards it
invalidated.* Before your close event, for every path you moved, renamed or
deleted this run:

1. Sweep every shard for findings whose `path` names it.
2. Rewrite `path` to the new location where the file moved, and set
   `"stale": true` where it did not — a delete, or a move you cannot resolve to
   a single destination.
3. Do nothing else to those findings. You do not close them, re-note them or
   judge them; you are correcting a coordinate, not answering a question.

`slice` is the wave whose entire perimeter is paths, so it is the only one that
can invalidate every other shard at once — but `split` and `drift` move files
too, and the duty is the same for all three. The failure this prevents is
specific and quiet: a wave opens its shard, finds the file missing, and closes
the finding as stale rather than hunting for where it went. Correctly identified
work disappears, and every count in the run still reconciles.

Line and column coordinates cannot be repaired this way, which is the reason not
to put them where nothing can reach them. A coordinate belongs in a structured
field a sweep can find — `sites[].range`, `path` — never in `note` prose.

**Record what you could not do.** Append to `coverage.json` (§7.4) for every
in-family signal you saw and were not permitted to act on, and raise a finding
(§7.2) for every one that has an owning wave and a `kind` that wave fires on.
File a concerns note (§8f) for every judgment call a later reader would
otherwise have to re-derive from the diff.

---

## §8. Wave order

```
 0        1       2        3        [·]        [·]         4          5        6       7        8
survey → slice → domain → literal → [cruddy] → [shelved] → affordance → boundary → split → lexicon → drift
  RO                                                                                                  RO
```

Controllers are shaped before the shelves they call: `shelved` requires
`cruddy` closed or skipped.

Three waves are conditional and carry no number of their own — a repo may run
the pipeline end to end without any of them firing:

- `literal` fires only on families whose rulebook has a `## literal` section.
  Today that is `ecmascript` alone; php, rust and nim fold the same extraction
  into `domain`. See `rules/families.md`.
- `cruddy` fires only when `ledger.stack` matches `laravel` or `php` **and** at
  least one open finding carries a `C`-prefixed rule. A php repo with no
  controllers writes `"cruddy": "skipped"` and does nothing. See `crud.md` §C0.
- `shelved` fires only when the stack's rulebook has a `## shelves` section —
  today `php` alone — **and** `cruddy` is closed or skipped. Its write scope is
  the data-access tree only; it creates files but never renames one, handing
  legacy filenames to `drift` through `rename_pending[]`. Doctrine:
  `shared/shelf.md`.

Being skipped is a normal outcome for all three, not a failure. `drift` must not
report a skipped wave as an unmet invariant.

`survey` is read-only **as to code**: it holds `Write` and `Edit` for
`trash/grain/` alone, because §7 makes it the author of every shard and of the
plan. `drift` is read-only
**as to decisions** — it raises nothing and closes nothing — but it does hold
`Edit` and `git mv`, because it is the one wave allowed to re-place files that
waves 2–5 created mid-pipeline. That is its mission, not an exception to it.

All mutating waves are `disable-model-invocation: true`. `survey` and `drift`
are auto-invocable. Every wave declares `user-invocable: true` explicitly.

## §8b. Non-wave skills

These ship in `skills/` alongside the waves but sit **outside** the wave order.
They are invoked deliberately, against a scope you name, and they touch no
ledger finding.

- `naming` — applies the family's `## slice` naming convention to one subfolder
  without running the pipeline.

A non-wave skill: opens no finding, closes none, and is never a prerequisite for
a wave. Its absence from §8 is deliberate — the wave order is a sequence, and a
standalone tool is not a step in it.

This section exists because absence from §8 is otherwise indistinguishable from
omission. Anything in `skills/` that is not in §8 must be listed here, or the
next reader cannot tell a deliberate exclusion from a forgotten one.

## §8c. Preflight skills

A **preflight** runs before the wave sequence and is not a member of it.

A preflight:

- MUST NOT create a ledger shard
- MUST NOT emit findings, or any record carrying `id`, `status`, `wave`, or `kind`
- MUST NOT be listed as a predecessor in any wave's ledger gate
- MUST write to a named advisory artifact under `trash/grain/`
- MAY be model-invocable, since it mutates nothing outside `trash/grain/`

The `absent artifact` convention is **inverted** for preflight artifacts. For
ledger shards, absent means skip. For a preflight artifact, absent means the
preflight has not run, and every dependent wave MUST halt. This inversion is
permitted only because preflights sit outside the sequence; a wave may never
carry it.

A preflight is distinct from a non-wave skill (§8b): `naming` runs beside the
pipeline and ignores the ledger, whereas a preflight runs before the pipeline
and is a precondition of it.

Current preflights: `doctor` → `trash/grain/capability.json`.
Doctrine: `shared/capability.md`.

## §8d. Runtime accelerators

A **runtime accelerator** speeds up a wave's own work without becoming part of
it.

An accelerator:

- MUST NOT create a ledger shard, emit findings, or produce any record
  carrying `id`, `status`, `wave`, or `kind`
- MUST NOT appear in any wave's ledger gate
- MUST write only under `trash/grain/forge/`
- MUST take the **LEDGER** absence convention: absent means degrade to
  in-model, never halt
- MUST NOT change any wave's output, only the cost of producing it
- MUST attribute every finding built on its output to `grain` (§7.2)

The absence convention here is the deliberate **contrast** with §8c. A
preflight inverts the convention — for a preflight artifact, absent means
halt — and that inversion is licensed by a preflight being a *precondition*
of the pipeline. An accelerator is by definition not a precondition of
anything, so it must never carry that inversion. An accelerator whose absence
halts a wave has stopped being an accelerator and become an undeclared
dependency.

Current accelerators: `forge` → `trash/grain/forge/`.
Doctrine: `shared/forge.md`. Owned by `survey`.

## §8e. The record

A **record artifact** states what a run did. It is written by every wave and
it closes nothing.

A record artifact:

- MUST NOT create a ledger shard, and MUST NOT carry an `F-` or `P-` id or a
  `status` field
- MUST NOT appear in any wave's ledger gate
- MUST be append-only, and MUST NOT be rewritten by any wave, including the
  wave that wrote a given line
- MUST take the **LEDGER** absence convention: absent means the run was not
  observed, never halt
- MUST NOT change any wave's output — a wave that behaves differently because
  the record exists has made the record a precondition, which §8d forbids for
  the same reason
- MUST digest every path, symbol and source fragment it holds
  (`observe.md` §4)

Current record artifacts: `events.jsonl`, `store/`, `saltmap.json`.
Doctrine: `shared/observe.md`. Written by every wave; `store/graph/` by
`survey` alone.

**Why the prohibition list differs from §8c and §8d.** Those two forbid `id`,
`status`, `wave` and `kind`. An event carries `wave` and `kind` and is still
not a finding, so the four-name list cannot be the real test — it is a proxy,
correct for a preflight and an accelerator and too blunt here.

The real test is whether a later wave can **close** something in the artifact,
and closure needs exactly two things: an id in a shared sequence, and a
status to change. Deny those two and a wave may label its lines however
clearly it likes; nothing in the file can be acted on, so nothing in it can
drift from the ledger. §8c and §8d keep their stricter list — a preflight and
an accelerator have no reason to name a wave, and letting them would invite a
reader to file them in the sequence.

**Write scope, and why every wave gets it.** §7.5 partitions the ledger so
that no wave edits another's conclusions. An append-only log holds no
conclusion to edit: a line is a statement about the moment it was written,
and a later wave appending its own line contradicts nothing. The partition
protects mutable state, and there is none here.

**The record is deletable and the ledger is not.** `rm -rf` on any record
artifact must always be safe, which is the invariant `observe.md` §7.4 states
as a test. That is what distinguishes this class from §7's: the ledger is the
JSON source of truth, the record is evidence about how it came to say what it
says.

**Execution is local.** No wave makes a network call, for any purpose,
including writing this artifact. `observe.md` §11 is doctrine for the whole
suite and not only for the record; it is stated there because that is where
the aggregation case it rules on is described.

## §8f. The concerns record

A **concerns note** states a judgment call in prose, for a human. It is written
by the wave that made the call and it closes nothing.

Path: `trash/grain/roots/<root>/concerns/<slug>.md`. Per-root, on §7.0's
reasoning: a concern is a fact about a decision taken in one root, and two roots
are two runs that happen to share a session.

A concerns note:

- MUST NOT carry an `F-` or `P-` id of its own, or a `status` field
- MUST NOT appear in any wave's ledger gate
- MUST take the **LEDGER** absence convention: absent means no concern was
  recorded, never halt
- MUST NOT change any wave's output
- MAY name findings, paths and symbols in plaintext — it is written for the
  human reading it, and unlike §8e it is not aggregated, not transmitted and not
  digested

**Required content.** Four things, because they are the four a later reader
cannot recover from the diff: what was done, the concern that remains, why the
doctrinally clean option was not taken, and what would actually resolve it.

**A deferral in prose is not a handoff.** A concerns note that hands work to
another wave MUST name the finding id it raised on that wave's shard (§7.2). The
next wave reads its shard, not this directory, and it does not re-read closed
findings. Without the id the work does not happen and nothing in the pipeline
notices — the note's own quality is no protection, because nothing machine-read
ever opens it.

The note exists **in addition to** the finding, never instead of it. Same for
`coverage.json`: prose here does not discharge the append there.

**Why this is a class and not a habit.** §8e's record answers *what did this run
do* and is digested, append-only and machine-shaped by construction. It cannot
hold *here is why the clean option was wrong*, and that is the sentence a human
returning in three months needs most. The two artifacts are not redundant; one
is evidence and the other is reasoning.

**Deletable, like §8e and unlike §7.** `rm -rf` on this directory must always be
safe. A concerns note that some wave's gate depends on has stopped being a
concerns note and become an undeclared precondition.

---

## §9. Tone

Corrections are kind and educational. Never show bad code without immediately
following it with the fix. If the code is already right, say so and say why.
Readability beats academic purity — when a rule would make code worse, note the
tradeoff and take the readable option, recording it as `exempt:readability`.
