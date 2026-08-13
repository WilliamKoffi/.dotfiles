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
`dist/`, `.next/`, or any `.gitignore`d path is not a root.

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
| `git` | 2.0 | all mutating | `required` | no | rollback boundary |
| `jq` | 1.6 | all | `required` | no | shard reads without full-file loads |
| `ctags` (universal) | 5.9 | `survey` | `required` | no | symbol index — `--fields=+ne --output-format=json` |
| `ast-grep` | 0.20 | `literal` `domain` `cruddy` `shelved` | `preferred` | yes | structural query and rewrite |
| `tokei` *or* `scc` | any | `survey` `split` | `preferred` | yes | LOC per file; feeds split thresholds |

`ctags` is `no` despite being the most heavily used tool in the pipeline. It
indexes; it makes no claim. A hub-in-leaf finding built on its ranges and
fan-in counts is grain's assertion, sourced `grain` and `heuristic` — the
worked example in `convention.md` §7.2.

`ctags` is `required` for `survey` alone. Without it there is no index, and
without the index every downstream wave falls back to whole-file reads — which
is the condition this whole tooling layer exists to eliminate.

### ECMAScript roots

| Tool | Floor | Waves | Severity | Ev |
|---|---|---|---|---|
| `node` | 18 | all | `required` | no |
| `tsc` | 5.0 | any mutating wave (post-mutation gate) | `required` | no |
| `knip` | 5.0 | `survey` `drift` | `preferred` | yes |
| `dependency-cruiser` | 16 | `boundary` | `preferred` | yes |
| `ts-morph` | 20 | `lexicon` `split` | `preferred` | no |

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

### Nim roots

| Tool | Floor | Waves | Severity | Ev |
|---|---|---|---|---|
| `nim` | 2.0 | all | `required` | no |
| `nim check` | — | any mutating wave (post-mutation gate) | `required` | no |
| `nim jsondoc` | — | `survey` | `preferred` | yes |

Nim is the thin ecosystem. Neither `ctags` nor `ast-grep` ships a Nim parser,
so the `required` `ctags` grant on `survey` is **waived for Nim roots** and
`nim jsondoc` substitutes as the index source. Record this waiver explicitly in
`capability.json` rather than leaving it implicit.

## §4 capability.json schema

```jsonc
{
  "generated_at": "2026-08-13T09:14:22Z",

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
      "waivers": []
    },
    {
      "path": "web",
      "stack": "nextjs",
      "rules_file": "rules/ecmascript.md",
      "detected_by": ["package.json", "next.config.mjs"],
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
      "satisfies": ["survey"]
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
