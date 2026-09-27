# capability.md

Doctrine for the `doctor` preflight. Cited by `skills/doctor/SKILL.md` and by
`survey` Gate 0. Nothing here is restated in a wave SKILL.md.

---

## §1 Standing

`capability.json` is an **advisory artifact**, in the same class as
`plan.json`:

| | Ledger shards | `plan.json` | `capability.json` |
|---|---|---|---|
| Created by | `survey` | `survey` | `doctor` |
| Contains findings | yes | no | no |
| Absent means | skip that wave | plan un-precomputed | **halt** — probe not run |
| Freezes anything | yes, via `closed_by` | no | no |

Note the asymmetry in row three. `capability.json` is the one artifact whose
absence is not a skip signal. This is why `doctor` is a preflight and not a
wave: the `absent shard = skip` contract holds across all eleven waves precisely
because `doctor` is outside the sequence and does not produce a shard.

## §2 Root detection

A **root** is a directory owning a manifest. Each root carries one stack, one
rules file, one required toolset. Workspaces may have many.

| Stack | Required signal | Disambiguator | `rules_file` |
|---|---|---|---|
| `laravel` | `composer.json` | `artisan` present at root | `rules/php.md` |
| `php` | `composer.json` | no `artisan` | `rules/php.md` |
| `nextjs` | `package.json` | `next` in deps **and** `next.config.*` | `rules/ecmascript.md` |
| `typescript` | `package.json` | `tsconfig.json`, no `next` | `rules/ecmascript.md` |
| `javascript` | `package.json` | no `tsconfig.json` | `rules/ecmascript.md` |
| `rust` | `Cargo.toml` | — | `rules/rust.md` |
| `nim` | `*.nimble` | — | `rules/nim.md` |

**Exclusions.** A manifest under `vendor/`, `node_modules/`, `target/`,
`dist/`, `.next/`, `trash/`, or any `.gitignore`d path is not a root. `trash/`
matters more than the others because grain's own forge tree lives under
`trash/grain/forge/` (`convention.md` §8d), and if the forge ever wrote a
manifest, that
manifest would carry a required detection signal for the table above.
`*.nimble` is the sharpest case — it is the *sole* signal for a nim root, so a
`.nimble` under `trash/grain/forge/` is one gitignore slip from grain
detecting its own accelerator as a project root and surveying itself. The
forge therefore writes no manifest of any kind, and `trash/` being gitignored
is enforced at `survey` Gate 0c rather than assumed.

**Workspace members.** A Cargo workspace or an npm workspace declares members
in its root manifest. Treat each member as its own root; treat the workspace
manifest as a root only if it also carries source.

**Ambiguity.** Contradictory signals — `tsconfig.json` with no TS files, a
`composer.json` with no `autoload` — produce `stack: null` and an `ambiguous`
note. `doctor` does not guess. The human rules.

## §3 Tool matrix

Severity is **per tool per wave**, not per tool.

- **`required`** — the wave refuses. Consistent with doctrine that out-of-order
  execution is refused rather than warned against.
- **`preferred`** — the wave proceeds using grain heuristics, and every finding
  produced in that category carries `source: "grain"` and `confidence:
  "heuristic"`.
- **`optional`** — the wave silently skips that category. No finding, no
  `coverage_misses[]` entry.

### Evidence

Each table below carries an **Ev** column. `yes` marks a tool as
**evidence-producing**: `convention.md` §7.2 draws the closed `source`
vocabulary from these entries and no others, so a tool marked `no` can never
appear as a finding's `source`.

The test is one question — **does this tool assert something about the code, or
does it verify, transform, or enable?** An assertion is a claim that maps to a
grain finding kind: *this export is unused*, *this file is 800 lines*, *this dependency
crosses a boundary*. Verification returns pass/fail, transformation rewrites,
and an interpreter or package manager merely makes the others runnable. None of
the three has an opinion to cite.

Classify a newly added tool by that question, not by resemblance to an existing
row.

`tsc` is the entry that looks misfiled and is not. Its diagnostics read as
assertions, but grain runs it as a post-mutation gate, and a gate's output is
pass/fail — the run either survives or is rolled back. Nothing in it becomes a
finding. The same reasoning covers `php -l`, `cargo check`, and `nim check`.

Evidence status is independent of severity: `ctags` is `required` and `no`,
`knip` is `preferred` and `yes`. One asks whether the wave can run, the other
what its output may be attributed to.

**Extensions inherit their host's token.** `larastan` and
`shipmonk/dead-code-detector` report through one PHPStan run and are sourced
`phpstan` (`convention.md` §7.2). They are marked `yes → phpstan` below: they
produce evidence, but not under a name of their own.

### Universal

| Tool | Floor | Waves | Severity | Ev | Purpose |
|---|---|---|---|---|---|
| `git` | 2.0 | `survey` + all mutating | `required` | no | enumeration boundary (`survey` Gate 0d) and rollback boundary |
| `jq` | 1.6 | all | `required` | no | shard reads without full-file loads |
| `ctags` (universal) | 5.9 | `survey` | `required` | no | symbol index — `--fields=+ne --output-format=json` |
| `ast-grep` | 0.20 | `literal` `domain` `cruddy` `shelved` | `preferred` | yes | structural query and rewrite |
| `tokei` *or* `scc` | any | `survey` `split` | `preferred` | yes | LOC per file; feeds split thresholds |

`ctags` is `no` despite being the most heavily used tool in the pipeline. It
indexes; it makes no claim. A hub-in-leaf finding built on its ranges and
fan-in counts is grain's assertion, sourced `grain` and `heuristic` — the
worked example in `convention.md` §7.2.

`git` is `required` for `survey`, not merely for the mutating waves. Gate 0d
makes `git ls-files` the enumeration boundary — the thing that decides which
files exist as far as the pipeline is concerned — so on a `survey` it is load
bearing before a single finding is raised. A non-git workspace does not halt;
it degrades to a Glob walk and records the degradation by name.

`ctags` is `required` for `survey` alone. Without it there is no index, and
without the index every downstream wave falls back to whole-file reads — which
is the condition this whole tooling layer exists to eliminate.

### Meta toolchain

| Tool | Floor | Waves | Severity | Ev | Purpose |
|---|---|---|---|---|---|
| `uv` | 0.5 | `survey` | `optional` | no | pins the forge interpreter; PEP 723 launcher |
| `nim` | 2.0 | `survey` | `optional` | no | compiles the forge accelerator |
| `nimble` | 0.14 | `survey` | `optional` | no | evidence of a complete Nim install |
| `lmdb` (headers + static archive) | 0.9.29 | `survey` | `optional` | no | build-time only; the KV of `observe.md` §7.5 |

This table is orthogonal to root stack. `nim` appears here for a Laravel root
and a Next.js root alike, because the accelerator is stack-agnostic by
construction (`forge.md` §B). Every other table in this section is keyed to a
root's stack; this one is keyed to grain itself. A reader will otherwise try
to file these rows under a stack — they don't belong to one.

Every row is `optional` and MUST remain so. Escalating any of them to
`preferred` or `required` would make an accelerator a precondition, which §8d
forbids. The forge can make a run faster; it must never make a run possible
that wasn't.

`nimble` is probed but never invoked. The forge has zero dependencies and
writes no `.nimble` manifest (§2). Its presence is read as evidence of a
complete Nim toolchain, nothing more.

**`lmdb` is a build-time row and probing it means probing for `lmdb.h` and
`liblmdb.a`, not for a binary on `$PATH`.** `mdb_stat` being present proves
nothing — grain never runs it. Package managers that split outputs put the
header and the archive in a development output that a plain profile install
does not pull in, so the probe is a file test at the resolved prefix and a
`command -v` result is not a substitute.

It is `optional` and must stay so, like every row in this table. Its absence
means the compiled engine uses the filesystem CAS, which is what it does
today regardless — `observe.md` §7.6 has not licensed the KV, and this row
exists so that `doctor` can report the fact rather than so that anything acts
on it.

`ruff`, `ty`, and `mypy` are deliberately absent from this table and from
every table in this section. They belong to grain's own CI, not to a user's
machine. Say this explicitly, because otherwise the next reader adds them, and
three tools get probed on every run to validate source that shipped
pre-checked.

`nim` appears twice in this section — as `required` for nim roots, and as
`optional` here. That is not a duplicate: one asks whether the ROOT can be
surveyed, the other whether the ACCELERATOR can be built. A workspace can have
the second without the first.

### Resolver engines

The engines that decide whether a symbol-graph edge is `resolved` or
`heuristic` (`observe.md` §9.2). Probed per family, on `survey` only.

| Tool | Family | Floor | Severity | Ev | Produces |
|---|---|---|---|---|---|
| `typescript-language-server` | ecmascript | 4.0 | `preferred` | no | `resolved` edges, all kinds |
| `intelephense` *or* `phpactor lsp` | php | any | `preferred` | no | `resolved` edges, all kinds |
| `rust-analyzer` | rust | any | `preferred` | no | `resolved` edges, all kinds |
| `nimlangserver` | nim | any | `preferred` | no | `resolved` edges, all kinds |
| `tree-sitter` | all | 0.22 | `preferred` | no | `resolved` intra-file, `heuristic` cross-file |

**`preferred`, not `required`, and it looks wrong.** `observe.md` §9.3 defers
any cross-file rename whose call-site set contains a heuristic edge, so a
missing language server visibly stops work — which reads like a `required`
tool. It is not. `required` means *the wave refuses*; here the wave runs,
produces its findings, and defers a subset with a written reason. That is the
definition of `preferred`, and promoting it would refuse a survey that has
useful output to give.

**Ev is `no` on every row, including the language servers.** A resolver
resolves; it does not conclude. `rust-analyzer` says *these are the call
sites*, and grain says *this is a hub in a leaf* — the same relation `ctags`
stands in, and the same ruling (`convention.md` §7.2). The extra strength of a
resolved answer is carried by `resolution` on the edge, which is a third axis
for precisely this reason (`observe.md` §9.1). It never leaks into a finding's
`confidence`, and no language server ever appears as a `source`.

**One engine per family per run**, selected at `survey` Gate 0e and held for
the whole wave, exactly as the forge engine is (`forge.md` §C). A graph whose
edges came from two resolvers has no single `engine` value to record, and
`observe.md` §8.3 requires one.

`phpactor` appears twice in this section — as `preferred` for `lexicon` under
PHP roots, and here. Not a duplicate: `lexicon` invokes its **mutation** CLI
and is forbidden to analyze with it (see the PHP table's third ruling), while
this row invokes its **language-server** mode and never mutates. Same binary,
two disjoint surfaces, and the PHP-table prohibition still stands.

### ECMAScript roots

| Tool | Floor | Waves | Severity | Ev |
|---|---|---|---|---|
| `node` | 18 | all | `required` | no |
| `tsc` | 5.0 | any mutating wave (post-mutation gate) | `required` | no |
| `knip` | 5.0 | `survey` `drift` | `preferred` | yes |
| `dependency-cruiser` | 16 | `boundary` | `preferred` | yes |
| `ts-morph` | 20 | `lexicon` `split` | `preferred` | no |
| `vitest` \| `jest` \| `node --test` | any | any mutating wave (post-mutation gate) | `preferred` | no |

### PHP roots

| Tool | Floor | Waves | Severity | Ev |
|---|---|---|---|---|
| `php` | 8.1 | all | `required` | no |
| `php -l` | — | any mutating wave (post-mutation gate) | `required` | no |
| `composer` | 2.0 | all | `required` | no |
| `phpstan` | 1.11 | `survey` `drift` | `preferred` | yes |
| `shipmonk/dead-code-detector` | 0.5 | `survey` | `preferred` | yes → `phpstan` |
| `larastan` | 2.0 | `survey` `cruddy` — **laravel roots only** | `preferred` | yes → `phpstan` |
| `rector` | 1.0 | `literal` `cruddy` `shelved` | `optional` | no |
| `deptrac` | 2.0 | `boundary` | `preferred` | yes |
| `phpactor` | 2024.x | `lexicon` | `preferred` | no |
| `phpinsights` | 2.0 | `drift` | `optional` | no |
| `pest` \| `phpunit` | any | any mutating wave (post-mutation gate) | `preferred` | no |

Two rulings encoded above:

**`larastan` is `preferred`, not `optional`, on Laravel roots.** Without it,
PHPStan reports false positives on facades, magic methods, and Eloquent
dynamic properties, which pollutes the ledger with findings no wave can close.

**`phpinsights` is `optional` and `drift`-only.** It scores; it does not find.
Its architecture percentage has no mapping to a grain finding kind and must not
be wired into `survey`.

**`phpactor` is mutation-only.** Its CLI surface is partial and its class moves
do not update docblock or non-PHP references. `lexicon` uses it to move, never
to analyze, and always verifies with the post-mutation gate.

### Rust roots

| Tool | Floor | Waves | Severity | Ev |
|---|---|---|---|---|
| `cargo` | 1.75 | all | `required` | no |
| `cargo check` | — | any mutating wave (post-mutation gate) | `required` | no |
| `cargo clippy` | — | `survey` `drift` | `preferred` | yes |
| `cargo machete` | any | `survey` | `optional` | yes |
| `cargo test` | — | any mutating wave (post-mutation gate) | `preferred` | no |

### Nim roots

| Tool | Floor | Waves | Severity | Ev |
|---|---|---|---|---|
| `nim` | 2.0 | all | `required` | no |
| `nim check` | — | any mutating wave (post-mutation gate) | `required` | no |
| `nim jsondoc` | — | `survey` | `preferred` | yes |
| `testament` | — | any mutating wave (post-mutation gate) | `preferred` | no |

Nim is the thin ecosystem. Neither `ctags` nor `ast-grep` ships a Nim parser,
so the `required` `ctags` grant on `survey` is **waived for Nim roots** and
`nim jsondoc` substitutes as the index source. Record this waiver explicitly in
`capability.json` rather than leaving it implicit.

### Test runners

Each family's table carries one test-runner row, alternatives separated by `|`:
the first one present satisfies it. Probe for the **runner**, never for test
files — a repo with a configured runner and no tests yet is a different fact
from a repo with neither, and only the runner is what the gate invokes.

**`preferred`, never `required`.** Every mutating wave's exit gate asserts *test
suite green, with no test modified*, and `rules/families.md` makes it a pipeline
invariant — so the row looks like it should block. It must not. Adding a test
framework is the repository's decision, not a refactor wave's, and a `required`
severity here would refuse to run the pipeline on any untested repo, which is a
large share of the repos most in need of it.

What the row buys instead is that the absence becomes **sayable**. Before these
rows existed, six waves asserted a clause `doctor` could not probe, `survey`
could not degrade on, and no wave could report — so every run skipped it in
silence and every gate went green. `convention.md` §5.1 is the consuming ruling:
the clause is recorded as unsatisfiable, naming the missing runner from
`gaps[]`, and never as satisfied.

This is the `severity` axis working as designed. `preferred` means *proceed,
degraded, and say so* — the same treatment `dependency-cruiser` and `ts-morph`
get, for the same reason.

## §4 capability.json schema

```jsonc
{
  "generated_at": "2026-08-13T09:14:22Z",
  "probed_scope": ".",
  "trash_ignored": true,
  "fingerprint": "4b1d9e0c77a2f3518ac6d240be95713f",

  "meta": {
    "uv": { "present": true, "version": "0.5.11" },
    "nim": { "present": true, "version": "2.2.6" },
    "nimble": { "present": true, "version": "0.16.4" },
    "python": { "resolved": "3.13.1", "via": "uv" }
  },

  "manifest_mtimes": {
    "composer.json": "2026-08-11T16:02:00Z",
    "web/package.json": "2026-08-12T21:40:11Z"
  },

  "roots": [
    {
      "path": "api",
      "stack": "laravel",
      "rules_file": "rules/php.md",
      "detected_by": ["composer.json", "artisan"],
      "resolver": "intelephense",
      "waivers": []
    },
    {
      "path": "web",
      "stack": "nextjs",
      "rules_file": "rules/ecmascript.md",
      "detected_by": ["package.json", "next.config.mjs"],
      "resolver": null,
      "waivers": []
    }
  ],

  "tools": [
    {
      "name": "ctags",
      "present": true,
      "version": "6.1.0",
      "floor": "5.9",
      "below_floor": false,
      "satisfies": ["survey"],
      "binary_hash": "7d1a0c8e5b62f4930ac7d1e04b8f2653"
    },
    {
      "name": "knip",
      "present": false,
      "version": null,
      "floor": "5.0",
      "below_floor": false,
      "satisfies": []
    }
  ],

  // omit this key entirely when there are no gaps
  "gaps": [
    {
      "tool": "knip",
      "root": "web",
      "blocks": ["survey", "drift"],
      "severity": "preferred"
    }
  ]
}
```

`roots[].waivers[]` holds entries of the shape
`{ "tool": "ctags", "wave": "survey", "reason": "no nim parser" }`.

**`probed_scope`** is the path `doctor` was invoked against, or `"."` when it
was invoked bare. It exists to prevent one specific silent failure: `doctor`
takes a `[path]`, so `/grain:doctor app` followed by `/grain:survey modules`
leaves `survey` iterating a `roots[]` that covers nothing its scope touches —
surveying zero roots while reporting success. `survey` Gate 0a halts when its
scope is not covered by `probed_scope`.

**`trash_ignored`** records the result of `git check-ignore -q trash`. `doctor`
records it and reports it; it never halts on it. Enforcement is `survey`
Gate 0c's, and the reason the fact is recorded here anyway is that a human who
learns it at preflight fixes it before `survey` refuses rather than after.

**`meta`** records the forge toolchain (§3 "Meta toolchain"). `python.resolved`
is the version `uv` selected, `python.via` is `uv` or `null`. Never record a
bare `python3` path — B1 makes `uv` the only interpreter provenance grain will
trust.

**`fingerprint`** is the capability fingerprint, §8. It is derived from the
rest of this file and is written last.

**`roots[].resolver`** names the engine selected for that root's family from
the "Resolver engines" table, or `null` when none was found. `survey` Gate 0e
reads it rather than re-probing; `null` is the degradation to `ctags`
(`observe.md` §9.2) and is reported by name.

**`tools[].binary_hash`** is present only for a tool grain **executes
directly** and omitted for every other row. It is a content hash of the
resolved binary, and §8.2 states why a version string alone is not enough for
these.

## §5 Staleness

`capability.json` is a session artifact. `survey` Gate 0 treats it as stale,
and halts, when **any** of the following holds:

1. The file is absent.
2. `generated_at` is more than 24 hours old.
3. Any path in `manifest_mtimes` has an on-disk mtime newer than its recorded
   value — a dependency changed since the probe.

Condition 3 is the load-bearing one. Conditions 1 and 2 are backstops.

## §6 Dependency on ledger provenance

The `preferred` severity tier is inert without `source` and `confidence` fields
on ledger findings. A degraded wave must be able to mark its output as
heuristic; if it cannot, `preferred` and `required` collapse into the same
behaviour and the whole matrix reduces to a binary.

**`doctor` cannot ship before the ledger provenance amendment lands.** Sequence
the two changes accordingly.

## §7 Dependency on the forge

The `meta` table and `probed_scope` are inert without `shared/forge.md` and
the §8d amendment to `convention.md`. `doctor` must not probe for `uv` or
`nim` before there is a documented accelerator class for them to serve — a
probe that records a capability nothing consumes is noise in an artifact
whose whole value is that every key is load-bearing.

Sequence: `convention.md` §8d, then `shared/forge.md`, then this table.

## §8 The capability fingerprint

`doctor` computes `fingerprint` last, after `tools[]`, `meta` and `roots[]`
are written, and it is a pure function of them:

    fingerprint = blake2b_128 over the sorted, length-prefixed list of
      "<name>=<version>"        for every probed tool, present or absent
      "<name>@<binary_hash>"    for every tool grain executes directly

Doctrine for what consumes it is `observe.md` §5 and §7.2. This section states
only what `doctor` must put in it.

### 8.1 — Absent tools are in the fingerprint too

An absent tool is recorded as `"<name>="` with an empty version. Installing
`ast-grep` must change the fingerprint, because a run with it and a run
without it produce different findings from the same source — and if those two
runs share a key, the cache serves one repo's answer to the other's question.

Omitting absent tools would make the fingerprint a function of what happened
to be installed rather than of the environment, which is the same defect §8.2
describes in a smaller costume.

### 8.2 — Versions, never presence

The fingerprint hashes version strings, and it hashes the binary itself for
anything grain executes directly.

A presence-only fingerprint — `{ctags: true, ast-grep: true}` — is stable
across a `ctags` 6.0 → 6.2 upgrade that changes emitted fields. Every artifact
cached under it is now wrong, is still served, and nothing reports a problem:
the cache is doing exactly what it was told. That failure produces incorrect
output that looks like fast output, on the one machine where the upgrade
happened, and it is the reason this section exists.

`binary_hash` covers the case a version string cannot: two builds of the same
advertised version, from different patches or different distributions. It is
recorded only for tools grain executes directly, because for everything else
the version is what the tool reports about itself and grain has no cheaper
handle on it.

**Record the resolved path alongside the hash.** `command -v` gives the path;
hash what it points at, not the name. On a content-addressed store the path is
*itself* a hash over source, patches, compiler and build inputs — strictly
stronger than anything §8.2 asks for, obtained for free.

That is a happy accident and never a dependency. `doctor` does not detect
which package manager produced a path and has no branch for one; it resolves,
hashes a regular file, and records both. A workspace on such a store gets a
better fingerprint without grain knowing it happened, which is the only way a
tool that must run anywhere is allowed to benefit from a tool that does not.

### 8.3 — It is computed on every invocation, like everything else here

`doctor` never caches (see "Never caches" in `doctor/SKILL.md`), and the
fingerprint inherits that. It is twenty hashes over strings already in memory
plus a content hash of at most a handful of binaries.

### 8.4 — A fingerprint change invalidates; it never migrates

There is no fingerprint-migration path and there will not be one. The store is
dropped. `observe.md` §7.4 states the ruling and its justification; it is not
repeated here.
