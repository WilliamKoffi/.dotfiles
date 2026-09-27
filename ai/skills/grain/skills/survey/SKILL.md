---
name: survey
description: Wave 0 of the refactor pipeline. Inventories the scope read-only and produces the ledger of findings. Modifies no code.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Glob, Grep, Write(trash/grain/roots/**), Edit(trash/grain/roots/**), Write(trash/grain/forge/**), Edit(trash/grain/forge/**), Write(trash/grain/store/**), Write(trash/grain/salt), Bash(git log *), Bash(git status *), Bash(git ls-files:*), Bash(git hash-object:*), Bash(git check-ignore:*), Bash(uv run:*), Bash(nim c:*), Bash(trash/grain/forge/bin/*:*), Bash(tree-sitter parse:*), Bash(tree-sitter query:*), Bash(rust-analyzer analysis-stats:*), Bash(phpactor references:*)
---

# Wave 0 — survey

Read-only **as to code**. You modify no code file. The files you may write are
the six under `trash/grain/roots/<root>/` — `ledger.json`,
`waves/<wave>.json`, `plan.json`, `coverage.json`, `events.jsonl`,
`saltmap.json` — plus whatever the forge writes under `trash/grain/forge/`
(`shared/forge.md`), the symbol graph under `trash/grain/store/graph/`
(`observe.md` §8), and `trash/grain/salt` on first run. See `convention.md`
§7, §7.0, §8d and §8e.

`Write` and `Edit` are granted for those trees and no other, enumerated
rather than blanket. Without them this wave cannot produce its own output, the
forge's, or the record's; the grant is the mission, not an exception to it.

`Write(trash/grain/salt)` writes once, on the first run in a workspace, and
never again. A rewritten salt orphans every digest ever recorded
(`observe.md` §4.1) — check for the file before writing it, and treat an
existing salt as immovable.

`Bash(trash/grain/forge/bin/*:*)` is the sharpest grant in the suite: it
executes a binary grain itself compiled. It is safe only because
`forge/src/` is a hash-verified copy of a static plugin asset and parameters
arrive as JSON on stdin, never interpolated into source. If the forge ever
generates code, this grant becomes arbitrary execution and must be
withdrawn.

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

### 0e — Engines

**Forge engine.** Select per the state machine in `shared/forge.md` §C, and
hold it for the whole wave. Not restated here.

**Resolver engine.** Read `capability.json.roots[].resolver` for each root.
Do not re-probe — `doctor` decided, and the answer is in the artifact, exactly
as with `rules_file` at Gate 0b. Hold it for the whole wave
(`capability.md` §3, "Resolver engines").

`null` is the degradation to `ctags`: every edge this wave emits is
`resolution: "heuristic"` (`observe.md` §9.2), and the degradation is named in
the run summary and written to the `decision` plane. It is not a halt — a
heuristic graph is the map this pipeline has always run on.

**A resolver grain cannot invoke in one shot is an absent resolver.** A wave
is a sequence of blocking calls, not a session host. Where a language server
offers only a stdio LSP session, there is no owner for that process's
lifecycle inside a wave, and starting one anyway leaves an orphan when the
wave exits early — which every gate in this file is designed to do. Use the
one-shot surfaces (`tree-sitter query`, `rust-analyzer analysis-stats`,
`phpactor references`) or record the resolver as absent. Holding a session is
a forge target (`forge.md` §E) and is not licensed today.

### 0f — Cache

`cache: "bypass"`, hardcoded. Do not read `trash/grain/store/objects/` or
`store/index/`, and do not create them. `observe.md` §6 states why, and §6.1
states the three conditions that would license reading them.

`store/graph/` is **not** the cache and is unaffected by this gate — it is an
emitted artifact (`observe.md` §8), written on every run, and read by no
step-key lookup.

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

   This pass is the forge's delegation target (`forge.md` §E). When an engine
   was selected at Gate 0e, feed it the Gate 0d file list and the ctags JSON
   and consume its fan-in table. When none was, do the pass in-model. The
   finding text, the hub-in-leaf judgement, and the note are grain's either
   way — the helper supplies counts, not conclusions.

   **Emit the graph.** The declarations are nodes and the call sites are
   edges; write them to `trash/grain/store/graph/<blob-sha>.json` per
   `observe.md` §8. Take the blob SHAs from `git ls-files -s` (`observe.md`
   §7.1) rather than hashing files yourself.

   This is a write, not a second computation. You have already derived every
   node and every edge in this file — today they are used once and discarded,
   which is why `observe.md` §8.1 calls this wave a producer that was throwing
   its product away.

   A file whose blob SHA already has a graph entry written under the current
   `capability.json.fingerprint` is **not** re-parsed. That is the one place
   this wave skips work on the basis of a stored artifact, and it is not the
   cache Gate 0f bypasses: the key is a content hash and a fingerprint, with
   no step key and no store index involved.

   Every edge carries `resolution`, `engine`, `fingerprint` and `blob`. An
   edge missing any of the four is malformed — `observe.md` §8.3 is what makes
   the graph auditable, and an unprovenanced edge forces a downstream wave to
   trust the whole graph or none of it.

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
  stays open forever. Report the `top-up` branch below as the alternative.
- **Existing ledger, overlapping scope, invoked as `top-up`** → **merge, with a
  duplicate filter.** See below.
- The overlap test is a normalised path-prefix check, after resolving `.` and
  trailing slashes.

### Top-up — re-surveying a scope that was already surveyed

Invoked deliberately, never automatically. It exists because a survey that
under-reports is otherwise unrepairable: only `survey` sees the whole scope, the
overlap rule refuses a second look, and `literal` and every other findings-driven
wave is explicitly forbidden a discovery mode. Without this branch the run's
single largest source of missed work has no remedy at all.

The invariant the refusal protects is **no two ids for one violation** — not
*never look twice*. So look twice, and enforce the invariant directly:

1. Build the existing key set: `(kind, path, symbol)` over every finding in
   every shard, whatever its `status`. Closed and exempt findings count — a
   violation someone already decided is not a new one.
2. Run the full pass. Discard every candidate whose key is already present.
3. Append what survives, allocating from `id_high_water`, and re-open any wave
   whose shard gains an open finding. Do not touch a single existing finding.
4. Append to `scopes[]` only if the scope string is new; a repeated scope is one
   entry, not two.

Report three numbers: candidates found, duplicates filtered, findings appended.
A top-up that appends nothing is a useful result and must not read as a failure.

**A wave already closed is not re-run by this.** Re-opening `waves.slice` because
its shard gained a finding is the manifest telling the truth; whether to re-run
the wave is the operator's call, and a top-up never makes it.

Write the branch taken to the `decision` plane, as with every other merge-rule
branch.

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

**`events.jsonl`** — the record, `observe.md` §2. Append as you go, never at
the end. A wave that halts at Gate 0a has produced the single most valuable
event in the file, and batching the writes until the ledger is ready loses
exactly the runs worth explaining.

Emit, at minimum: every gate outcome including the ones that passed, every
degradation named in the run summary, the two engine selections from Gate 0e,
the merge-rule branch taken below, and one `trace` event per step with its
duration. Digest every path and symbol (`observe.md` §4) — the run summary is
plaintext for the human in front of you, the record is not.

**`saltmap.json`** — digest → plaintext, for every digest you wrote this run.
Local only, and it never leaves the machine (`observe.md` §4, §11).

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

**`kind` vocabulary.** This list is authoritative — `convention.md` §7 defers to
this block, and its own examples are illustrative. A wave needing a new `kind`
adds it here first. One invented mid-run is a `coverage_misses[]` entry, not a
finding field.

| `kind` | Fired on by | You may emit it |
|---|---|---|
| `naming` | `slice` | yes |
| `literal-cluster` | `literal` | **no** — `domain` only |
| `repository` | `shelved` | **no** — `domain` only |
| `boundary` | `boundary` | yes |
| `route-file` | `cruddy` | yes |
| `defect` | **nobody** | yes, under the rule below |

**A finding's `kind` is what routes it.** A wave fires on a `kind`, not on a
shard — being on `waves/literal.json` is not the same as being in the shape
`literal` consumes. File work under a `kind` its owning wave does not fire on
and it sits open forever while every count in the run reconciles.

**`defect` means no wave owns it.** The ruling is `convention.md` §7.5; what
follows is how it lands on you.

The trap is specific and you will meet it. You cannot emit `literal-cluster` —
you do not have the view of the concept a cluster represents, and only `domain`
does. So a repeated-literal violation you see has no correct `kind` available to
you, and `defect` is the nearest thing. **Use it, and say so in the `note`:**
name the wave the work belongs to, in those words. `domain` audits this shard
and re-raises what it finds (`domain/SKILL.md`, "Audit the shard you inherit"),
and the `note` is what tells it which findings to look at.

A banned construct is the sharpest case. Where the family's rulebook bans a
construct outright — a TypeScript `enum` — the finding is not a permanent
`defect`. It is the largest piece of that wave's work in the file, and it will
be read by nobody unless the `note` routes it.

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

### Reconcile the counts, per file

The asymmetry check above is per-extension and will not catch a uniform
shortfall. Before writing the ledger, reconcile three numbers you already hold
from Gate 0d:

    enumerated:      every file the Gate 0d list returned
    family_files:    those whose extension maps to a loaded rulebook
    surveyed:        those item 7 actually walked

`surveyed` must equal `family_files`. Where it does not, **enumerate the
difference into `coverage_misses[]`** — one entry per unsurveyed file, with
`why_missed` — before writing `coverage.json`. Report all three numbers.

`coverage_misses: []` alongside `surveyed < family_files` is not a pass. Both
statements cannot be true, and the empty array is the artifact that was supposed
to detect exactly this. A third of a scope can go unsurveyed with every other
gate green, and nothing downstream will ever say so: the shards will simply look
like a codebase with less wrong with it than it has.

**A shard is a floor, not a ceiling.** Say that in the run summary whenever the
reconciliation is inexact or the resolver degraded, so no later wave reads its
shard as the complete set of work in its category.

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
- `surveyed` equals `family_files`, or every file in the difference is an entry
  in `coverage_misses[]` with a `why_missed`. All three counts are reported.
- Every finding carries a `path`, including `literal-cluster` findings carrying
  a `home` (`convention.md` §7.2)
- Every `kind: "defect"` covering work an owning wave would fire on names that
  wave in its `note`
- The absence of a test runner, where `capability.json` reports one, is named in
  the run summary (`convention.md` §5.1)
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
- `events.jsonl` holds an event for every gate outcome, and its `seq` values
  are contiguous from 0
- No event, no graph entry and no store object holds a plaintext path, symbol
  or source fragment
- Every graph edge carries `resolution`, `engine`, `fingerprint` and `blob`
- `trash/grain/store/objects/` and `store/index/` were not created
  (`observe.md` §6)
- No network call was made (`observe.md` §11)
