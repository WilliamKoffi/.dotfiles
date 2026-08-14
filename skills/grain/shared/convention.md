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
- No behavior fixes. If a skill finds a bug, it records it and moves on. A bug
  fix is a separate commit by a human.
- No dependency additions. No config changes. This constrains the user's
  repository, not `trash/`: anything grain builds for its own use under
  `trash/grain/` adds no dependency to any manifest, writes no config file the
  repo will read, and is removed by deleting one gitignored directory.

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
  roots/<root>/
    ledger.json            manifest — run facts and wave status. Never findings.
    waves/<wave>.json      findings owned by that wave.
    plan.json              artifacts the pipeline intends to create. Advisory.
    coverage.json          coverage_misses[]. Append-only by any wave.
```

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

The shape is the contract. A wave opens exactly two files —
`roots/<root>/ledger.json` and `roots/<root>/waves/<itself>.json` — so write scope is enforced by what it holds open rather than by
an instruction telling it to behave. Per §0, a constraint that survives only in
prose is a constraint that drifts.

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
      "source": "grain",
      "confidence": "heuristic"
    }
  ]
}
```

**Status values:** `open` → `closed` | `deferred` | `blocked` | `exempt`

**Optional fields**, written by the wave that closes a finding and read by later
waves: `created[]` lists files the wave wrote — `lexicon` and `drift` skip them,
because a name set by doctrine this run must not be re-decided in the same run.
`touched[]` lists files it edited. `rename_pending[]` hands a legacy filename to
`drift` without doing a `git mv`. `plan_id` points at the artifact in
`plan.json` this finding is closed by building.

**Cross-shard deferral.** A finding carrying `defer_to: "<wave>"` stays in the
deferring wave's shard with `status: "deferred"`. The named wave does **not**
act on it this run — it is the next `survey`'s input. No wave writes into
another wave's shard under any circumstance; the single exception in this file
is `stale` on `plan.json`, §7.3.

Sharding makes this rule load-bearing rather than polite. In one flat file a
misrouted write was merely untidy; here it is a wave reaching into a document it
never opened.

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

**`source` is shared with the plan; `confidence` is not.** §7.3 gives plan
entries a `source` too, and deliberately so: both answer *what authority stands
behind this record*, a finding citing a tool and a plan entry citing a doctrine
section. One concept, two domains, no ambiguity.

`confidence` is finding-only. The plan's neighbouring field is
`determination` — a different axis, named apart on purpose. See §7.3.

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

A wave appends an entry whenever it acts on a symbol no finding covers. `drift`
reports the total and the per-extension breakdown as a gate line.

This file is the **one named exception** to the contract below: it is
append-only by any wave, authored by whichever wave found the gap. It closes
nothing and it opens nothing — `findings[]` remains survey-only. Giving it its
own file rather than a key inside a shard is deliberate: an entry authored by
`split` about a gap in `affordance` belongs to neither shard.

Its purpose is arithmetic. A miss noticed once is an anecdote; nine misses
sharing an extension are a defect. Scattered across per-wave report objects they
never add up, which is how a detector gap survives an entire pipeline run.

### 7.5 — Contract

- Only `survey` creates findings, and only `survey` creates plan entries.
- A wave mutates its own shard and the manifest key bearing its own name. Its
  only write elsewhere is `stale` on `plan.json`.
- No wave closes, edits, or reads-to-mutate a finding in another wave's shard.
- `drift` reads every shard, the manifest, the plan and the coverage file; it
  mutates no status.
- A wave whose shard holds zero open findings writes `"status": "skipped"` to
  the manifest and exits without opening a source file.
- A wave that builds a plan entry lists the file in the closing finding's
  `created[]`. From that moment the name is frozen against `lexicon` and
  `drift`.
- A wave reads and writes only under `trash/grain/roots/<its own root>/`.
  Cross-root reads are forbidden; two roots are two runs that happen to share a
  session.
- A wave whose manifest status is `blocked` does not run and writes nothing.
  `survey` set that status; the wave never opens to contest it.

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

---

## §9. Tone

Corrections are kind and educational. Never show bad code without immediately
following it with the fix. If the code is already right, say so and say why.
Readability beats academic purity — when a rule would make code worse, note the
tradeoff and take the readable option, recording it as `exempt:readability`.
