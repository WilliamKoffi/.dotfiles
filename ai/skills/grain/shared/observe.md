# observe.md

Doctrine for the **record** — grain's event log, its content-addressed store,
its symbol graph, and the rules governing where any of it may run. Cited by
`convention.md` §8e, by `skills/survey/SKILL.md`, `skills/drift/SKILL.md` and
`skills/doctor/SKILL.md`. Nothing here is restated in a SKILL.md.

One file rather than two, and deliberately so: §10 makes the replay corpus and
the cache the **same substrate**. A run's recorded inputs are what a cache keys
on and what an evaluation replays. Splitting the two into separate doctrine
files would put one mechanism in two documents, which `convention.md` §0 names
as the drift condition.

---

## §1 Standing

The record is the fifth artifact class.

| | Ledger shard | `plan.json` | `capability.json` | `forge.json` | The record |
|---|---|---|---|---|---|
| Created by | `survey` | `survey` | `doctor` | `survey` | every wave |
| Contains findings | yes | no | no | no | no |
| Absent means | skip that wave | plan un-precomputed | halt — probe not run | go slower | **nothing was observed** |
| Freezes anything | yes, via `closed_by` | no | no | no | no |
| Deletable | no | no | no | yes | yes |

The record's absence is the only one in the row that changes neither what the
pipeline does nor how fast it does it. It changes only what can be said about
the run afterwards. That is why it is a class of its own and not a variant of
the accelerator: an accelerator missing costs time, a record missing costs
evidence, and the two failures are repaired by different people on different
days.

**Every wave writes it.** This is the single exception to `convention.md`
§7.5's write-scope contract, and it is licensed by the record carrying no
`id`, `status`, `wave` or `kind` — nothing in it can be closed, and no wave
can reach through it into another wave's decisions. The contract exists to
stop waves editing each other's *conclusions*; an append-only log of what each
wave did contains no conclusion to edit.

## §2 The three planes

Three kinds of fact, one file, discriminated by a `plane` field.

| `plane` | Records | Written by |
|---|---|---|
| `decision` | gate outcomes, refusals, degradations, engine adoption, tier assignment | the wave, as it decides |
| `trace` | step durations, cache state, subprocess argv hash, byte counts | the wave, as it works |
| `outcome` | accepted, edited, immediately re-run, reverted within the window | a **later** run, §2.2 |

Path: `trash/grain/roots/<root>/events.jsonl`. One handle, opened append-only,
one event per line.

### 2.1 — One file, not three

`coverage.json` earned its own file (`convention.md` §7.4) because an entry
authored by `split` about a gap in `affordance` belongs to neither shard. The
planes are the opposite case: all three describe **one run**, and the whole
value of the decision plane is joining it to the trace and outcome planes on
`run_id`. Three files means three handles, three partial fsyncs, and a join
that has to reconcile three truncation points after a crash.

The discriminator goes in the record, not in the filename, for the same reason
`convention.md` §7.1 keeps run facts in one manifest: a partition encoded in a
path is a partition nothing validates.

### 2.2 — Outcome is written retrospectively, never by the producing run

A run cannot observe its own reception. The wave that emits a finding does not
know whether a human will accept it, edit it, immediately re-run the wave, or
revert the commit next Tuesday.

Outcome events are therefore written by a **later** invocation — `drift`, or a
subsequent `survey` — carrying the *original* `run_id` in a `subject_run`
field and their own `run_id` in the envelope. Two ids, because the question
*when was this observed* and the question *what is being observed* have
different answers and a single id cannot hold both.

**The revert window is a field, not a constant.** An `outcome` event of kind
`reverted` carries `window_days` stating the window that was applied.
Recording it in the event is what stops a later change of the window silently
reclassifying history: a reader that hardcodes 14 days will reinterpret every
event ever written the moment someone argues for 30.

Default window: 14 days. It is a default, and every event states the one it
used.

### 2.3 — A degradation is a decision, not a trace

Degradations, refusals and waivers go in the `decision` plane even though they
feel like incidents. The test is whether grain *chose*: to proceed with
`heuristic` output, to refuse an overlapping scope, to waive `ctags` on a Nim
root. Each is a choice made against doctrine, and the decision plane is the
record of choices.

Getting this backwards buries every degradation among timings, which is where
the one question the record exists to answer — *why did this run produce that*
— becomes unanswerable.

## §3 The event envelope

```jsonc
{
  "schema": "grain.event/1",
  "event_id": "9f2c4ab1e7d035c6a8b1f4e2c90d7a53",
  "tenant_id": "local",
  "run_id": "01J8ZQ4M7K3XW2P0R5T6Y8N1DV",
  "seq": 47,
  "plane": "decision",
  "ts": "2026-08-16T10:02:11.418Z",
  "wave": "survey",
  "root": "api",
  "kind": "degradation",
  "body": { }
}
```

Every event carries all of the above. `body` is plane-specific and is the only
key whose shape varies.

### 3.1 — The four hard fields

These four are hard because retrofitting any of them means rewriting history
or carrying two readers forever. The rest can be added later at the cost of a
`null`.

| Field | Ruling |
|---|---|
| `schema` | `"grain.event/<n>"`. Present on the first event ever written. A stream whose first line has no schema tag is unreadable by any later version, and there is no repair that does not involve guessing. |
| `event_id` | `blake2b_128` hex over the canonical encoding of every field **except `event_id`**. Content-hashed, so the same event emitted twice deduplicates on merge without a coordinator. A random id makes an idempotent append impossible, which is exactly what a crashed-and-retried wave produces. |
| `tenant_id` | Present from the first event. Local runs write `"local"`. Adding a tenant key later means every historical event is untenanted and every reader carries a branch for it — permanently, because history does not shrink. |
| `seq` | Monotonic integer per `run_id`, starting at 0, incremented once per event regardless of plane. **Ordering is `seq`, never `ts`.** |

**Wall clocks skew.** NTP steps backwards, a suspended VM resumes with a stale
clock, a container inherits the host's drift. `ts` is recorded because a human
reading the log wants it, and it is never authoritative: two events with the
same `ts` and a `seq` gap of 3 are ordered by `seq`, and an event whose `ts`
precedes its predecessor's is not an error worth reporting.

`run_id` is a random 128-bit identifier rendered as a sortable string. It is
**not** subject to `forge.md` §D's determinism rules — §D governs cache output,
where an environmental value causes a false divergence. The record is not cache
output. A run identifier that were deterministic across runs would defeat its
own purpose.

### 3.2 — Never repurpose a field

A field's meaning is fixed at the moment it is first written. To change what a
field holds: add a new one, and mark the old one deprecated in this section.
Never widen a type, never add a value to a closed vocabulary without a schema
bump, never reuse a retired name.

The failure this prevents is silent and total. A reader written against
`grain.event/1` that encounters a repurposed field does not error — it
computes a wrong number from a correctly-parsed value, and every aggregate
built on it is wrong in a way no test catches. `convention.md` §7.1's
`id_high_water` exists for the analogous reason in the ledger: a counter that
can go backwards produces collisions nobody notices.

Deprecated fields keep being written until the next schema major, with their
documented meaning intact.

### 3.3 — Deprecations

None yet. This section is created empty on purpose: an amendment that adds the
first deprecation should extend a list, not invent a convention under time
pressure.

## §4 Digests over content

**No source content, no path, and no symbol name leaves the machine in
readable form.** Every such value is recorded as a salted digest.

    digest = blake2b_128(salt || value_utf8_bytes)

`salt` is 128 random bits generated once per workspace and written to
`trash/grain/salt`. It is never transmitted, never written into an event,
never placed in the store, and never committed — `trash/` is gitignored
(`convention.md` §7).

The salt map — digest → plaintext — is `trash/grain/roots/<root>/saltmap.json`
and is local by the same rule. It exists so a human reading their own log can
resolve a digest back to the file it names.

### 4.1 — Per workspace, not per run

A per-run salt would make no two runs joinable, which destroys the trace and
outcome planes at once: the whole question *did the file we flagged last week
get reverted* is a join on a path digest across runs.

### 4.2 — An unsalted hash is not a digest

`sha256("src/Http/Controllers/UserController.php")` is not private. The path
space of a real repository is small, highly conventional, and for anything
open-source, published. A rainbow table over one framework's conventional
layout recovers most of a repo's structure from unsalted hashes in seconds.

The salt is the entire mechanism. Stating it plainly here because the failure
mode looks like success — the log is full of hex either way.

### 4.3 — What this buys

Source never leaves the machine, and an aggregated event stream is unjoinable
to any repository by anyone who does not hold that repository's salt. This is
the correct privacy posture and it is the strongest thing grain can say about
itself. It is a consequence of the design, not a policy layered on top, which
is why it belongs in doctrine rather than in a README.

## §5 The capability fingerprint

`doctor` computes a **capability fingerprint** and writes it to
`capability.json`. It is a component of every step key (§7.2) and every graph
entry (§8).

**Its construction is `capability.md` §8 and is not restated here.** That file
owns the probe, so it owns the formula; this section owns what the record does
with the result. One mechanism, one home — `convention.md` §0.

### 5.1 — What consumes it

| Consumer | Effect of a change |
|---|---|
| step key (§7.2) | every key differs; nothing hits |
| graph entry (§8) | every file is re-parsed on the next `survey` |
| `forge.json` (`forge.md` §C) | the compiled binary is rebuilt |

All three are **total invalidations**, and that uniformity is the design. A
fingerprint that invalidated some artifacts and not others would need a map of
which tool affects which artifact — a map that is wrong the first time someone
adds a tool and does not update it.

### 5.2 — A fingerprint change invalidates; it never migrates

There is no fingerprint-migration path and there will not be one. §7.4 states
the ruling and its justification for the store; it applies unchanged here.

The cost of getting this wrong is stated in `capability.md` §8.2 and is worth
reading once: a stale fingerprint serves incorrect output that looks like fast
output, on the one machine where a tool was upgraded.

## §6 The cache-bypass ruling

**Ship with `cache: "bypass"` hardcoded.** Not a configuration key defaulting
to bypass — hardcoded, with no code path that enables the store.

An option that can be turned on will be turned on, and from that moment the
`trace` plane's durations are a mixture of cold work and hits from a cache
nobody has validated. The numbers that were supposed to justify building the
cache have been contaminated by the cache.

### 6.1 — What licenses §7

§7 is written and it is **not licensed to run**. The gate is arithmetic, and
it is checkable rather than a matter of taste:

1. The `trace` plane holds complete wave-order durations for **at least three
   distinct roots**, across at least two stacks.
2. The p50 duration of the candidate step exceeds the measured p50 cost of a
   store round-trip for that step's payload size, by a factor of at least 4.
3. The step is deterministic under a fixed fingerprint — demonstrated by
   replay (§10), not asserted.

Condition 2 is the one that fails in practice. A step taking 40ms does not
want a cache; it wants to not be called 3000 times, which is a different
repair and a cheaper one. Measure first, and let the measurement rule out the
cache as readily as it licenses it.

Until all three hold, `store/` is not created and the digests of §4 are
written to the event log alone.

## §7 The store

### 7.1 — Input digests come from git

Git has already computed a content hash for every tracked file. Recomputing it
costs a full read of the working tree, which is the same order of work as the
analysis the cache exists to skip.

| Need | Command |
|---|---|
| tracked blob SHAs | `git ls-files -s -- <scope>` |
| untracked blob SHAs | `git ls-files --others --exclude-standard -z -- <scope> \| git hash-object --stdin-paths` |
| cheap pre-check | `git status --porcelain=v2` |

`git status --porcelain=v2` runs first. When it reports a clean tree, the
index's SHAs are authoritative and no file is read at all.

This extends `survey` Gate 0d's ruling rather than adding a second mechanism:
`git ls-files` is already the enumeration boundary, and `-s` asks the same
command for the hashes it was going to print paths for.

**Non-git workspace:** the store is unavailable, and the run degrades exactly
as Gate 0d degrades — named in the run summary, never silent. A hand-rolled
hash walk is not a fallback; it is the cost the store existed to avoid.

**A blob SHA is a fact about content, not about location.** Two identical
files share one SHA. That is a feature for per-file analysis (§8) and a trap
for anything path-dependent: the path-dependent part of a step key comes from
the scope id, never from the blob.

### 7.2 — The step key

    step_key = blake2b_128( length_prefixed(
        skill_version,
        engine_version,
        capability_fingerprint,   // §5
        scope_id,
        input_digest              // §7.1
    ) )

`blake2b` is `hashlib` in Python and `std/hashes`-adjacent in Nim's standard
distribution. Stdlib on both sides, so this survives `forge.md` §G's
no-dependency constraint without an argument.

**Every component is length-prefixed.** Plain concatenation makes `("ab","c")`
and `("a","bc")` the same key. This collision is silent, rare, and produces one
wrong cached answer in an otherwise correct run — the hardest class of bug in
the whole design, bought off for four bytes per component.

`digest_size=16` (128 bits). 256 bits buys nothing here: the adversary is
accident, not attack, and the key is never a security boundary.

### 7.3 — Two-tier CAS

```
trash/grain/store/
  objects/<aa>/<remaining-hex>     immutable, content-addressed
  index/<name>.jsonl               mutable pointers, append-only
  graph/                           §8
```

**`objects/` is immutable.** An object is written to a temp file in its own
final directory and moved into place with an atomic rename. Never written in
place, never updated, never locked. Immutability is what removes locking from
this design entirely: two concurrent writers producing the same object write
identical bytes, and the loser's rename is harmless.

**`index/` is mutable and append-only.** A pointer update appends a record;
the last record for a key wins. Compaction rewrites the file whole and happens
**at wave boundaries only** — the one class of moment at which no step is in
flight. A mid-wave compaction exposes a reader to a half-written index, and
the append-only shape is what makes recovery from a torn write mean *drop the
last line*.

**Grain never deletes an object.** The only supported deletion is
`rm -rf trash/grain/store/`.

### 7.4 — The store is a cache, not state

> `rm -rf trash/grain/store/` must always be safe.

The ledger under `trash/grain/roots/` remains the JSON source of truth. If
deleting the store ever loses a decision, a finding, or a plan entry, the store
has stopped being a cache and the design has failed — that is the invariant,
stated as a test anyone can run.

**Gate: a schema mismatch drops the store. It never migrates it.**

Migration code must be correct against every historical shape that ever
existed, is exercised only on upgrade, and its payoff is a rebuild you get for
free by deleting a directory. The risk is unbounded and the saving is one
run's work. The same reasoning is why `convention.md` §7.4 gives coverage its
own file rather than a versioned key inside a shard: cheap to rebuild beats
clever to preserve.

This applies identically to a capability-fingerprint change (§5.3).

### 7.5 — Fast KV inside the forge binary only

The interpreted engine uses the filesystem CAS of §7.3. The compiled engine
may additionally use an embedded key-value store.

This maps exactly onto the n/n+1 handoff already in `forge.md` §C — run *n*
is interpreted, run *n+1* is compiled — so the storage split falls along an
engine boundary that exists and is already enforced at wave entry. No new
state machine.

Two rulings constrain it:

**The KV is a read-through view over the same CAS, never a second source of
truth.** It may be deleted independently and rebuilt from `objects/`. A KV
holding an object the CAS does not is a divergence with no adjudicator.

**The test is linkage, not provenance.** The built binary must have **no
dynamic dependency** on the KV library. Where the object code came from —
vendored C source, a distribution package, a Nix store path — is not the
question and never was.

| Configuration | Build needs | Run needs | Verdict |
|---|---|---|---|
| vendored C source, compiled by `nim c` | nothing | nothing | licensed |
| system or Nix library, **statically** linked | headers + `.a` at build | nothing | licensed |
| system or Nix library, **dynamically** linked | headers + `.so` at build | that exact library, forever | **refused** |

Provenance was the proxy this section first reached for, and it was wrong in
the same way `convention.md` §8e's four-name list is wrong: it names a
correlate instead of the property. The property is that a compiled forge
binary runs on the machine that holds it, with nothing else installed.
`convention.md` §8d says an accelerator whose absence halts a wave is not an
accelerator; a binary that dies in the dynamic linker is that failure in its
purest form.

**The dynamic case fails at the worst possible moment.** `survey` Gate 0e
selects the engine and `forge.md` §C holds it for the whole wave. A missing
shared library is not discovered at a gate — it is discovered at `execve`,
after the engine decision is frozen and possibly mid-batch. Under Nix this is
not hypothetical: the binary's RPATH names a store path, and
`nix-collect-garbage` after a `nix profile remove` deletes it. The tool that
made the library available is the tool that revokes it.

**The gate is one line and it runs at build time.** After `nim c`, the binary
must show no KV library in `ldd` output (or `otool -L`). Fail it and the build
is discarded, `nim.quarantined` stays false — nothing was validated, so
nothing is quarantined — and the run continues on the filesystem CAS.

**RocksDB stays ruled out, on grounds that survive a good package manager.**
"Hard to build" was never the real reason and a Nix expression disposes of it:

- It is C++. Linking it means `--cc:cpp` for the whole helper or a C shim,
  which reopens `forge.md` §G's compile line and §D's determinism story.
- Static linking pulls a transitive closure — snappy, lz4, zstd, gflags —
  each of which must also be static and each of which lands in the
  fingerprint.
- Its behaviour is tunable in ways that change **what you read back**:
  comparators, compaction, bloom filters. LMDB's API is roughly ten functions
  with no knob that alters a returned value.
- The workload is single-writer, read-mostly, content-addressed, and
  thousands of keys. That is an mmap'd B-tree's shape, not an LSM tree's.

### 7.6 — The KV has its own gate, and it is not §6.1's

§6.1 licenses the **store**. It does not license the KV, and satisfying it
says nothing about whether LMDB beats the filesystem.

Reading a few thousand content-addressed blobs from `objects/<aa>/<rest>` is
a workload the OS page cache already serves well. LMDB wins at millions of
keys and at random small reads the page cache cannot hold; grain has neither
today. The KV is licensed only when the `trace` plane shows CAS reads are a
p50 cost worth attacking **after** §6.1 has been met — which is to say, two
measurements deep, not one.

Installing a KV library changes nothing about this. It removes an obstacle to
work that is not yet justified, and an unjustified optimization with its
obstacle removed is the most likely one to get built anyway. Stated here for
that reason.

## §8 The symbol graph

`survey` emits the symbol graph as a **first-class artifact**, keyed by blob
SHA:

    trash/grain/store/graph/<blob-sha>.json

```jsonc
{
  "blob": "e83c5163316f89bfbde7d9ab23ca2e25604af290",
  "fingerprint": "4b1d9e0c77a2f3518ac6d240be95713f",
  "engine": "lsp",
  "nodes": [
    { "sym": "a41f…", "kind": "function", "line": 42, "exported": true }
  ],
  "edges": [
    { "from": "a41f…", "to": "9c2b…", "kind": "call",
      "resolution": "resolved", "blob": "e83c…" }
  ]
}
```

Symbol names are digested (§4). `blob` on an edge names the file the edge was
**read from**, which is not always the file either endpoint lives in.

### 8.1 — survey is a producer, not a consumer

`survey` item 7 already computes exactly this: module-level declarations
(nodes) and fan-in counts (edges). Today that work is done, used once inside
the wave, and discarded. Emitting it is a write, not a computation — the
marginal cost of the artifact is serialization.

### 8.2 — Keyed by blob SHA, so incremental rebuild is free

A file whose content did not change has an identical blob SHA and an identical
graph entry, so it is never re-parsed. Two identical files across two roots
share one entry. Neither property requires an invalidation mechanism; both
fall out of content addressing (§7.3).

**The graph is workspace-scoped while the ledger is root-scoped**
(`convention.md` §7.0), and the difference is not an inconsistency: a blob SHA
is a fact about content, a finding is a fact about a place. Sharing content
facts across roots is correct; sharing findings across roots would break the
per-root `F-` sequence.

### 8.3 — Every edge carries provenance

`resolution` (§9), the `engine` that produced it, the `fingerprint` under
which it was produced, and the `blob` it was read from. Four fields, on every
edge.

This is the property no comparable tool ships, and it is the one that matters
for grain's purpose: a graph you cannot audit edge by edge is unusable for
mechanical rewrite (§9), whatever it scores on retrieval. An edge without
provenance forces the pipeline to trust the graph wholesale or not at all,
and neither is a position a refactoring tool can hold.

### 8.4 — The graph is not a ledger artifact

It carries no `id`, `status`, `wave` or `kind`, closes nothing, and lives
under `store/`. §7.4 therefore governs it: deleting it is always safe, and it
is rebuilt by the next `survey`.

## §9 Resolution — recall versus completeness

### 9.1 — `resolution` is a third axis and gets a third name

| Field | Lives on | Axis | Values |
|---|---|---|---|
| `confidence` | a finding (`convention.md` §7.2) | who asserted it | `proven` · `heuristic` |
| `determination` | a plan entry (`convention.md` §7.3) | how completely doctrine specifies the target | `mechanical` · `judged` |
| `resolution` | a graph edge (§8) | whether the edge was resolved or guessed | `resolved` · `heuristic` |

A finding never carries `resolution`; an edge never carries `confidence`.
`convention.md` §7.3 already named `determination` apart from `confidence` on
exactly this reasoning, and a third axis reusing either name would collapse a
distinction the pipeline branches on.

### 9.2 — Engines are probed, and the tier follows the engine

| Available | Edge kind | `resolution` |
|---|---|---|
| LSP for the family | any | `resolved` |
| tree-sitter, no LSP | intra-file | `resolved` |
| tree-sitter, no LSP | cross-file | `heuristic` |
| `ctags` only | any | `heuristic` |

tree-sitter parses; it does not resolve names across files. Recording its
cross-file edges as `resolved` because the parse succeeded is precisely the
error this table exists to prevent — a correct parse of a call site says
nothing about which declaration the call reaches.

Degrading to `ctags` is a **named degradation** in the `decision` plane and in
the run summary (`survey` Gate 0a), never a silent fallback.

### 9.3 — The doctrine ruling

> **A heuristic edge is adequate for orientation and disqualifying for
> mechanical rewrite.**

Consequences, binding:

- A `judged` plan entry may rest on heuristic edges. It is asking a human a
  question, and an approximate map is a fine basis for a question.
- A `mechanical` plan entry may not. `convention.md` §7.3 defines mechanical
  as derivable from doctrine by rule; a rule applied to a guessed input yields
  a guess wearing a rule's confidence.
- A wave renaming an exported symbol requires **every** call-site edge in the
  set to be `resolved`. One heuristic edge defers the whole rename —
  `blocked:unresolved` — per `convention.md` §5, which already requires all
  call sites to be updated in the same pass. An unresolved edge means the set
  of call sites is unknown, and §5 does not permit a partial pass.
- A **threshold rule** counting consumers — `ecmascript.md ## slice`'s "`shared/`
  only from three independent consumers onward", and every rule shaped like it —
  **may** rest on heuristic edges, and the finding it justifies MUST record that
  it did: `confidence: "heuristic"`, and a `disposition` naming the count as
  unverified. `drift` reports the tally (`drift/SKILL.md`, Resolver gate).

### 9.3.1 — Why a threshold records and a rename blocks

The two look alike and fail differently, so the ruling differs.

A rename is **total**: §5 requires every call site updated in one pass, so a
single unseen edge does not degrade the result, it breaks the build. A missing
consumer is a missing edit.

A threshold is **ordinal**: it asks whether a count crosses a line. A missing
consumer moves a file that should have stayed, or leaves one that should have
moved — recoverable at the next `survey`, visible to the typecheck, and wrong in
a way a human reading the ledger can spot. It does not corrupt.

The deciding argument is the counterfactual. Blocking thresholds on `resolved`
edges would halt the pipeline on every ctags-only root — which is currently
every root — for a class of decision that a one-shot resolver cannot always
settle either: dynamic imports are invisible to `ctags` outright, and a
threshold applied over them is soft whatever the tier says. A rule that stops
the whole pipeline and still does not guarantee the answer is not paying for
itself.

So: proceed, and mark it. What this forbids is the quiet version — a threshold
decision recorded at `confidence: "heuristic"` while the decision it supports is
treated downstream as settled, which is how a soft input becomes a hard fact
without anyone deciding it should.

### 9.4 — Why this is written down

This is the rule that stops a future maintainer adopting a benchmark-shiny
tool. Retrieval benchmarks reward recall: finding more candidate edges scores
better than finding fewer. This pipeline needs the opposite property —
knowing which edges are *certain*, because §9.3 turns on that and not on
coverage.

A tool that wins on recall and loses on resolution is a downgrade for grain,
and its benchmark will not say so. Neither will its README. Stated here so the
comparison is made on the axis that matters.

## §10 Replay and evaluation

Recorded inputs in the CAS plus the event log make a **replay corpus**. Replay
runs skill version B over the inputs version A saw, and reports what changed.

This is the mechanism that answers *did this skill version get better* before
it ships, and it needs no substrate of its own — it is the cache's substrate,
read instead of written.

### 10.1 — Replay compares decisions, not prose

The comparison is over `decision`-plane events: gate outcomes, refusals,
degradations, engine adoption, the finding set and its provenance fields. Not
over rendered text.

Two runs producing identical findings with differently-worded notes are the
same run for evaluation purposes. A prose diff reports that as a change and
buries the one line where a gate flipped.

### 10.2 — A replay writes no ledger and no outcome event

A replayed run had no human, therefore it had no reception. Writing an
`outcome` event for it would inject synthetic acceptances into the one plane
whose entire value is that it records what a person actually did (§2.2).

A replay writes `decision` and `trace` events under its own `run_id`, tagged
`replay: true` in the envelope's `body`, and touches
`trash/grain/roots/` not at all.

### 10.3 — The corpus is stored digested

A replay corpus is a recording of real repositories and is the most sensitive
artifact grain holds. §4 applies to it without exception, and it is subject to
§11 like everything else: it lives on the machine that produced it.

## §11 Execution locus

> **grain runs fully offline. Every wave, every gate, the store, the graph and
> the event log complete with no network.**

Any cloud component is aggregation, evaluation, or control plane, and **can
never be a precondition of a wave**.

This is structurally the same clause as `convention.md` §8d: an accelerator
whose absence halts a wave has stopped being an accelerator. A control plane
whose absence halts a wave has stopped being a control plane and become a
dependency — and grain would then be a service, with a service's failure
modes, on a task that is entirely local by nature.

Consequences, binding:

- No wave makes a network call. Not for telemetry, not for a model registry,
  not for a version check.
- `doctor` probes locally installed binaries and nothing else. It has no
  remote catalogue.
- The event log is written locally. Upload, if it ever happens, is a separate
  deliberate act by a separate tool — never a side effect of a wave.
- `tenant_id` (§3.1) exists so that aggregation is *possible*. It does not
  make aggregation *assumed*, and its presence in a local run's events is not
  consent to transmit them.

### 11.1 — Consent is a file, not a flag

Upload is opt-in per workspace, recorded at `trash/grain/consent.json`.
Absence means no, and absence is the shipped state.

A flag lives in a session and follows whoever typed it. Consent to transmit a
recording of a repository is a property of that repository's owner, not of
whoever happens to run the pipeline that afternoon — so it is recorded where
the repository is, and a CI runner that never saw the file transmits nothing.

## §12 Distribution

### 12.1 — Publish a benchmark, with a harness

The credibility bar for a tool in this category is now a published benchmark
with an official harness that a third party can run. Grain's harness is §10's
replay corpus, run over a public repository set.

**Every timing number is reported alongside the resolution-tier mix (§9.2) of
the run that produced it.** A speed comparison between a resolver and a
guesser is not a comparison, and publishing one — even honestly measured —
invites exactly the adoption §9.4 exists to prevent.

### 12.2 — One-line install, and it installs the plugin only

The install line installs grain. It does not install `ctags`, `uv`, `nim`, or
any analysis tool.

This is `doctor`'s "never installs" ruling reaching the distribution layer:
the same reason a preflight writes `remedy.sh` rather than running it is the
reason the installer does not reach for a package manager. A one-line install
that mutates a developer's toolchain is not convenience, it is the thing
`doctor` was designed not to do.
