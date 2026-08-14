---
name: survey
description: Wave 0 of the refactor pipeline. Inventories the scope read-only and produces the ledger of findings. Modifies no code.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Glob, Grep, Write(trash/grain/roots/**), Edit(trash/grain/roots/**), Bash(git log *), Bash(git status *), Bash(git ls-files:*), Bash(git check-ignore:*)
---

# Wave 0 — survey

Read-only **as to code**. You modify no code file. The only files you may write
are the four under `trash/grain/roots/<root>/` — `ledger.json`,
`waves/<wave>.json`, `plan.json`, `coverage.json`. See `convention.md` §7 and
§7.0.

`Write` and `Edit` are granted for that tree and no other, enumerated rather
than blanket. Without them this wave cannot produce its own output; the grant is
the mission, not an exception to it.

## Gate 0

### 0a — Capability

Read `trash/grain/capability.json`.

**Halt if absent.** Report: "Preflight has not run. Execute `/grain:doctor`."
Do not proceed on the assumption that tools are present. Do not probe for them
inline — that is doctor's remit, not survey's.

**Halt if stale**, per `shared/capability.md` §5: `generated_at` older than 24
hours, or any path in `manifest_mtimes` with a newer on-disk mtime. Report which
condition tripped and direct the user to re-run `/grain:doctor`.

**Halt if `probed_scope` does not cover `$scope`.** Report both paths and direct
the user to re-run `/grain:doctor` against the right path. Why: iterating
`roots[]` against an uncovered scope surveys zero roots and reports success.

**Halt if any `gaps[]` entry has `severity: "required"`** and lists `survey` in
`blocks[]`. Name the tool and point at `trash/grain/remedy.sh`.

**Read *all* `required` gaps**, not only those listing `survey` in `blocks[]`.
For each, write `"status": "blocked"` with a `reason` to that wave's manifest
key (`convention.md` §7.1), and name every blocked wave in the run summary. This
prevents a specific failure: a missing `tsc` blocks every mutating wave's
post-mutation gate but not `survey`, so today the run starts, mutates through
waves 1–5, and dies at wave 6 with the mutations already landed.

**Proceed with degradation** if the only gaps blocking `survey` are `preferred`.
Every finding in a degraded category is emitted with `source: "grain"` and
`confidence: "heuristic"`. State the degradation in the run summary — do not let
it pass silently.

**Skip the category** for `optional` gaps. No finding, and no
`coverage_misses[]` entry: an uninstalled tool is not a coverage miss.

### 0b — Rules resolution

For each entry in `capability.json.roots[]`, load that root's `rules_file` and
scope its detection to that root's `path`.

This replaces inline stack inference. You no longer read manifests to decide
which rulebook applies — doctor already did, and the answer is in the artifact.
A root recorded with `stack: null` and an `ambiguous` note is not surveyed;
report it and continue with the roots that resolved.

### 0c — Self-ingestion

Run `git check-ignore -q trash`. Halt if it fails:

> "`trash/` is not gitignored. `survey` would enumerate its own ledger as
> source. Add `trash/` to `.gitignore`, then re-run."

`convention.md` §7 states this as a prerequisite in prose, and prose is what
fails on a fresh repo's first run: nobody adds the entry before the first
survey, `--others` then returns `trash/grain/*.json`, and `survey` reads its own
output as input.

### 0d — Enumeration

Build the file list **once**:

    git ls-files --cached --others --exclude-standard -- <root>/<scope>

This **replaces filesystem walking** for every subsequent step, including item 7
and every grep. It honours nested `.gitignore`s, the global gitignore, and
`.git/info/exclude` — none of which a hand-maintained denylist will ever track —
and it cannot follow a symlink out of the repo. By construction it excludes
`vendor/`, `node_modules/`, `target/`, `.next/`, and `trash/`.

Three riders:

- Apply `capability.md` §2's static exclusion list as a **second** filter.
  `--cached` still lists tracked-but-now-ignored files — someone committed
  `vendor/` before ignoring it.
- **Not a git repo:** fall back to `Glob` plus the exclusion list, and record a
  named degradation in the run summary. A filesystem walk is strictly weaker,
  and the user must know which one ran.
- **Refuse outright** when `$scope` resolves inside an excluded path. Do not
  return an empty list. An empty survey and a refused one are indistinguishable
  in the ledger, and only one is a mistake.

## Input

Rulebooks resolved in 0b. For each family present, read the sections of every
wave so you know what to look for.

**Conditional doctrine.** You also read the doctrine files the plan needs, and
only those:

| File | Load when |
|---|---|
| `shared/crud.md` §C1–C9 | `stack` matches `laravel` or `php` |
| `shared/shelf.md` §S1–S5 | the stack's rulebook has a `## shelves` section |

Neither is loaded otherwise. A wave-0 pass that reads controller doctrine for a
Rust repo pays a token cost for a plan it cannot emit.

## Work on `$scope`

1. File tree, by extension and by family.
2. Dependency graph between directories. Report cycles.
3. Slice candidates: which files change together (`git log --name-only` over the
   last 200 commits).
4. Duplicated utilities, hooks, schemas, types.
5. Dead code: **any** declaration with no consumer — exported or module-internal.
   An export-graph scan is not sufficient and never has been.
6. Untouchable zones (`src/legacy/`, vendored, generated).
7. **Symbol inventory.** For every file in scope, whatever its extension, list
   its module-level declarations: exports, plain function declarations, and
   const-arrow bindings. For each, record its fan-in — how many call sites, and
   whether they are inside the host file or outside it.

   This pass is what makes items 4 and 5 answerable at symbol level, and it is
   the input to `hub-in-leaf` in the `## split` section of the rulebook. Skipping
   it on `.tsx` because the file "is a component" is the specific mistake this
   item exists to prevent: a component file holds ordinary functions like any
   other module, and a function with thirteen internal call sites is a hub
   whether or not it is exported.

   Pass the Gate 0d list to ctags via `ctags -L -` rather than letting ctags
   walk the tree itself. One enumeration, one source of truth.

For each problem detected, emit a finding **addressed to the wave that owns
it**. Propose no edit.

A target name is not an edit. Where doctrine fixes what a finding's replacement
must be called, emit that name as a plan entry — §8 below. What you never do is
write the replacement, or choose between two branches doctrine leaves open.

## Output

One complete ledger set per root in `capability.json.roots[]`, written
independently under `trash/grain/roots/<root>/` (`convention.md` §7.0). Write
each manifest last: it reports counts, so it cannot be correct before the shards
exist.

**The merge rule.** Which of write-whole and update applies is decided per root,
not left to taste:

- **New root, or no existing ledger** → write whole.
- **Existing ledger, same root, non-overlapping scope** → merge. Append to
  `scopes[]`, allocate ids from `id_high_water`, append findings to the existing
  shards, and re-open any wave whose shard gains an open finding.
- **Existing ledger, overlapping scope** → **refuse**, reporting both scopes. An
  overlap produces two ids for one violation; a wave closes one and the twin
  stays open forever.
- The overlap test is a normalised path-prefix check, after resolving `.` and
  trailing slashes.

**`ledger.json`** — the manifest, `convention.md` §7.1. Run facts and one
`waves` entry per shard you wrote, each `"status": "open"`. Your own entry is
`"status": "closed"` with `findings` and `plan_entries` counts.

**`waves/<wave>.json`** — one file per owning wave, holding only that wave's
findings:

    {
      "wave": "slice",
      "findings": [
        { "id": "F-001", "family": "ecmascript", "rule": "2.5",
          "kind": "naming", "path": "src/hooks/user-hook.ts",
          "note": "dash instead of dot", "status": "open",
          "raised_by": "survey", "closed_by": null,
          "source": "grain", "confidence": "heuristic" }
      ]
    }

Write no shard for a wave with zero findings. Its absence is the skip signal,
and an empty `findings[]` array says the same thing more expensively.

**`coverage.json`** — `{ "coverage_misses": [] }`. You create it empty; later
waves append.

A finding may carry extra fields specific to its owning wave — for example
`kind: "literal-cluster"`, opened by `domain` for the `literal` wave (see
`domain/SKILL.md`). `survey` never generates that `kind` itself: it does not
have the view of the concept a literal cluster represents; only `domain` does.

**Provenance is mandatory.** Every finding carries `source` and `confidence`
(`convention.md` §7.2). A finding you derived by reading files, matching names,
or applying a rulebook section yourself is `source: "grain"`, `confidence:
"heuristic"` — that is most of what this wave produces. Write
`confidence: "proven"` only where a tool's own output is the evidence, and name
that tool in `source`. Inferring a fact a tool *would* have found is still
`heuristic`: the tier records who saw it, not how sure you feel.

A finding missing either field is malformed. Later waves branch on them, and a
finding that omits them silently claims the stronger tier.

**`kind` vocabulary.** `naming`, `literal-cluster`, `repository`, `boundary`,
`route-file`, `defect`. This list is authoritative — `convention.md` §7 defers
to this block, and its own examples are illustrative. A wave needing a new
`kind` adds it here first. One invented mid-run is a `coverage_misses[]` entry,
not a finding field.

Sequential, stable identifiers, allocated across all of a root's shards from one
`F-` sequence — and `P-` likewise for the plan. Both sequences are **per-root**
and both are allocated from `id_high_water` in that root's manifest, which
`survey` raises before writing the manifest. Never reuse a retired id; the
high-water mark, not the maximum id currently present, is what makes that
enforceable across runs.

## §8. The plan

`plan.json` (`convention.md` §7.3) is the artifact list: for every finding whose
resolution is a **new file**, the file that doctrine says to create. It is the
output a human reads when the run stops early — the findings diagnose, the plan
prescribes.

Emit an entry for every finding of `kind` `route-file`, `repository`, or
`literal-cluster` whose closure creates a file. Link the two: the finding
carries `plan_id`, the entry carries `from[]`.

### 8.1 — Two tiers, and the line between them

| `determination` | You emit | Because |
|---|---|---|
| `mechanical` | `path`, `class`, `actions[]`, `uri`, `route_name` in full | doctrine names the target by rule, from the source name alone |
| `judged` | those five as `null`, plus `question` | doctrine offers a branch, and choosing is the owning wave's job |

Mechanical, in practice:

    findActiveUsers()             → ActiveUsers            shelf.md §S3
    getExpiringSubscriptions()    → ExpiringSubscriptions   shelf.md §S3
    PodcastController@episodes    → PodcastEpisodeController  crud.md §C3
    POST /orders/store            → POST /orders            crud.md §C9.4
    GET  /Order_Items             → GET  /order-items       crud.md §C9.6

Judged, in practice — emit the question, not a guess:

    publish/unpublish   → crud.md §C5: update() or PublishedPodcastController?
                          question: "does the change have its own button?"
    invoice + invoices  → crud.md §C9.7: which spelling is the resource?

The tier is not a confidence score you feel your way to — it is not
`confidence`, which is the finding-level field and a different axis entirely
(`convention.md` §7.2). It is a fact about the doctrine section: if the section states a transformation, the entry is
mechanical; if it states a choice, the entry is judged. A judged entry filled in
by guessing reads identical to a mechanical one downstream, and the wave that
adopts it has no way to know a decision was invented rather than derived.

### 8.2 — `rewritable`, on URI entries only

Evaluate `crud.md` §C9.8 conditions **2 and 3** and no others:

- **2** — grep the repo for the literal path, on the full prefix, never on one
  generic segment.
- **3** — the external-binding word list and the unauthenticated-HTML test.

Write `"rewritable": "false"` when either fails, `"unknown"` otherwise. Never
`"true"`. Condition 1 — the route name surviving byte-identical — is a property
of the rewrite, and the rewrite is `cruddy`'s.

### 8.3 — One artifact, one entry

Two findings that resolve into the same new file share one plan entry and both
carry its `plan_id`. `subscribe` and `unsubscribe` are two findings and one
`SubscriptionController`. An entry emitted per finding produces two half-built
controllers in whatever a human does by hand.

## Coverage

Item 7 runs on **every** extension the family declares. Before writing the
ledger, count the symbol-level findings you are about to emit, grouped by file
extension, and report the table.

If one extension has zero symbol-level findings while another has many, say so
explicitly rather than shipping the ledger. That asymmetry is the signature of a
detector that swept one extension and skipped the other. It may be a true
result; it is more often a miss.

## Exit gate

- No code file modified
- `capability.json` was read, and any degradation it declared is named in the
  run summary
- Every finding carries an owning wave and a family, and lives in that wave's
  shard and no other
- The manifest names every shard written, and no shard it did not write
- Extensions not covered by a rulebook are listed explicitly
- The symbol inventory (item 7) covered every extension in the family, and the
  per-extension count of symbol-level findings is reported
- Every plan entry is `mechanical` with its fields filled, or `judged` with them
  `null` and a `question` written. Neither half-filled.
- No plan entry carries `"rewritable": "true"`
- Every `plan_id` on a finding resolves, and every plan entry has at least one
  finding pointing at it
- Every ledger path written is under `roots/<root>/` for a root present in
  `capability.json`
- `scopes[]` contains no overlapping pair
- `id_high_water` is `>=` every id written this run
- Every wave blocked by a `required` gap carries `"status": "blocked"` with a
  `reason`
