---
name: doctor
description: Preflight capability probe for the grain pipeline. Detects which stacks are present in the workspace, which analysis tools are installed and at what version, and which waves are blocked by missing tooling. Writes trash/grain/capability.json and, when gaps exist, trash/grain/remedy.sh. Run before /grain:survey. Never installs anything, never edits source, never emits ledger findings.
allowed-tools: Read, Glob, Grep, Write(trash/grain/capability.json), Write(trash/grain/remedy.sh), Bash(command -v:*), Bash(git rev-parse:*), Bash(git --version:*), Bash(git check-ignore:*), Bash(jq --version:*), Bash(ctags --version:*), Bash(tokei --version:*), Bash(scc --version:*), Bash(ast-grep --version:*), Bash(sg --version:*), Bash(node --version:*), Bash(npm --version:*), Bash(npx tsc --version:*), Bash(npx knip --version:*), Bash(npx depcruise --version:*), Bash(php --version:*), Bash(composer --version:*), Bash(vendor/bin/phpstan --version:*), Bash(vendor/bin/phpinsights --version:*), Bash(vendor/bin/rector --version:*), Bash(vendor/bin/deptrac --version:*), Bash(phpactor --version:*), Bash(cargo --version:*), Bash(nim --version:*), Bash(nimble --version:*), Bash(uv --version:*), Bash(uv python list:*), Bash(tree-sitter --version:*), Bash(rust-analyzer --version:*), Bash(nimlangserver --version:*), Bash(intelephense --version:*), Bash(typescript-language-server --version:*), Bash(b2sum:*), Bash(sha256sum:*)
disable-model-invocation: false
user-invocable: true
argument-hint: [path]
---

# grain:doctor

Preflight. Not a wave.

`doctor` sits outside the wave order. It emits no findings, creates no ledger
shard, and closes no category of work. It answers one question — *can this
pipeline run here, and against what* — and writes the answer to
`trash/grain/capability.json` for every wave to read.

Read `shared/capability.md` before proceeding. It holds the stack detection
signals, the tool→wave severity matrix, and the `capability.json` schema. This
file is procedure; that file is doctrine.

---

## Position

```
doctor ──▶ survey → slice → literal → domain → cruddy → shelved
           → affordance → boundary → split → lexicon → drift
```

`doctor` is not a member of the sequence. It does not appear in ledger gates as
a predecessor wave. `survey` Gate 0 checks for a fresh `capability.json` and
halts if absent — it does not invoke `doctor` itself.

## Non-negotiables

**Never installs.** No package manager is in the tool grant. When a gap is
found, write the remediation to `trash/grain/remedy.sh` and stop. Installation
is a human act performed outside this session. This is structural, not
advisory: the grant contains no `Bash(npm install:*)`, no `Bash(composer
require:*)`, no `Bash(cargo install:*)`, no `Bash(sh:*)`.

**Never reads source.** `doctor` inspects manifests, lockfiles, and config
files only — `composer.json`, `package.json`, `tsconfig.json`, `Cargo.toml`,
`*.nimble`, `artisan`, `next.config.*`. It does not open a `.php`, `.ts`,
`.tsx`, `.rs`, or `.nim` file. If you find yourself reading application code,
you have left the skill's remit.

**Never emits findings.** `capability.json` is advisory, like `plan.json`.
It contains no `id`, no `status`, no `wave`, no `kind`. Nothing in it can be
closed by a later wave.

**Never caches.** Re-derive on every invocation. Roughly twenty `command -v`
calls cost less than reasoning about whether a cached probe is still true, and
doctrine holds that stale data must be re-derived rather than adopted.

**Never transmits.** No network call, for any reason — not a version check,
not a registry lookup, not a telemetry ping. The grant contains no `curl`, no
`wget`, no `npm view`. `observe.md` §11 binds the whole suite; it is restated
as a non-negotiable here alone because `doctor`'s job — *what is installed* —
is the one that most naturally reaches for a remote catalogue to answer it.

**Never halts on a missing tool.** `doctor` halts in exactly one case — step 1,
when no root is found, because there is nothing to probe. It never halts on a
gap, however severe. Three reasons, stated compactly:

- §1 defines an absent `capability.json` as *"probe not run"* and makes that a
  halt at `survey`. A `doctor` that halts mid-probe writes no artifact, so
  `survey` can no longer distinguish "doctor never ran" from "doctor ran and
  found gaps" — two states §1's table deliberately separates.
- `remedy.sh` would carry one line. The human installs one tool, re-runs,
  discovers the next. A batch probe exists to prevent exactly that loop.
- Severity is per tool per wave (§3). "Required" is never a workspace verdict.
  A missing `deptrac` blocks `boundary` and nothing else.

Enforcement is `survey` Gate 0a's. `doctor` reports; `survey` refuses.

---

## Procedure

### 1. Establish roots

Walk the workspace for manifest files. Each manifest marks a **root** — a
directory with its own stack, its own rules file, and its own required
toolset. A monorepo with a Laravel API and a Next.js frontend has two roots.

Apply the detection signals in `shared/capability.md` §2. Record for each root:
`path`, `stack`, `rules_file`, `detected_by`.

If a manifest is found inside `vendor/`, `node_modules/`, `target/`, or any
path excluded by `.gitignore`, skip it. Vendored manifests are not roots.

If no root is found, halt. Report that the workspace contains no recognized
stack and that grain has nothing to operate on.

Then run `git check-ignore -q trash` and record the result as `trash_ignored`.
Do **not** halt on it — that is `survey` Gate 0c's job — but report it in step
6, so a human learns of it before `survey` refuses rather than after.

### 2. Probe tools

For each tool listed in `shared/capability.md` §3, run its version probe.
Batch the probes; do not run them one call at a time.

Record `present` (boolean), `version` (string or null), and whether the
version clears the `floor` given in the matrix. A present-but-below-floor tool
is recorded as present with `below_floor: true` and is treated as absent for
gap purposes.

Probe only the tools relevant to the roots found in step 1. A workspace with
no `composer.json` does not need a PHPStan probe.

Probe the meta toolchain (`shared/capability.md` §3 "Meta toolchain") on
**every** workspace, regardless of which root stacks are present — the
accelerator is stack-agnostic, so this probe is not gated on any root's
manifest. For `uv`, also run `uv python list` to record which interpreter
versions are available without downloading one. Record all of it under
`meta`.

Probe the resolver engines (`shared/capability.md` §3 "Resolver engines") per
root family. Record the winner as `roots[].resolver`, or `null` when none is
present. Prefer a language server to `tree-sitter` where both exist — §9.2 of
`observe.md` gives tree-sitter `heuristic` on cross-file edges, and cross-file
is where the tier decides whether a rename can run at all.

Hash the binaries grain **executes directly** — `ctags`, `ast-grep`, the
selected resolver, `tree-sitter` — and record each as `tools[].binary_hash`.
Resolve the path with `command -v` and hash what it points at, not the name.
Omit the key for every other tool. `capability.md` §8.2 states why a version
string alone is insufficient for these and sufficient for the rest.

### 3. Compute gaps

For each root, intersect the required toolset against what was found. For each
missing tool emit a `gaps[]` entry carrying:

- `tool` — the binary or package name
- `root` — which root needs it
- `blocks[]` — the waves degraded or refused
- `severity` — `required` | `preferred` | `optional`

Severity comes from the matrix in `shared/capability.md` §3. Do not invent
severities and do not promote a `preferred` tool to `required` because it
seems important.

**If there are no gaps, omit the `gaps` key entirely.** Do not write an empty
array. Absent means clear.

### 4. Write capability.json

Schema in `shared/capability.md` §4. Write to `trash/grain/capability.json`.

Set `generated_at` to the current UTC timestamp in ISO 8601. Set
`manifest_mtimes` to the modification time of every manifest found in step 1 —
this is what lets `survey` detect that a dependency changed since the probe.

Write `probed_scope` — the `[path]` argument, or `"."` when invoked bare — and
`trash_ignored` from step 1. `survey` Gate 0a halts when its scope falls outside
`probed_scope`, so an unwritten key here reads downstream as an unprobed
workspace.

Write `meta` from step 2's toolchain probe, and `roots[].resolver` from its
resolver probe.

Compute `fingerprint` **last**, per `shared/capability.md` §8. It is a pure
function of `tools[]`, `meta` and `roots[]`, so it cannot be correct before
they are written — the same ordering rule `survey` follows for its manifest.

Absent tools go into the fingerprint with an empty version string, not
omitted (§8.1). Installing a tool must change the fingerprint, because
installing one changes what the pipeline finds.

### 5. Write remedy.sh, if needed

Only when `gaps[]` is present. One commented line per gap, grouped by root,
each showing the install command a human would run. The file is generated, not
executed. Do not chmod it. Do not offer to run it.

If a gap has no clean install path — Nim tooling, a tool absent from the
platform's package manager — write the line as a comment with a URL rather
than a guessed command.

Meta-toolchain gaps are `optional` severity (§3 "Meta toolchain"), and their
remedy lines must say so plainly — a human reading `remedy.sh` must be able
to tell "grain will refuse without this" from "grain will be slower without
this" at a glance. For `nim`, write no guessed package-manager command;
platform coverage is too uneven, so write a URL comment instead, same as any
other gap with no clean install path. For a missing conforming Python
interpreter, the line is `uv python install 3.13`.

### 6. Report

A short table to the user: roots found, tools present, gaps by severity. Then
one of:

- No gaps → *"Clear. Run `/grain:survey`."*
- Only `optional` / `preferred` gaps → name the degradations, then *"You can
  proceed; findings from degraded categories will carry `confidence:
  heuristic`."*
- Any `required` gap → *"`/grain:survey` will refuse. See
  `trash/grain/remedy.sh`."*

Add one line when `trash_ignored` is false: *"`trash/` is not gitignored.
`/grain:survey` will refuse until it is."*

Add the forge line. One of:

- meta complete → *"Forge available. First survey runs Python and builds the
  accelerator; the next adopts it."*
- `uv` absent → *"No forge. Surveys run in-model."*
- `uv` present, `nim` absent → *"Forge runs interpreted only; no accelerator
  will be built."*

Add the resolver line, one per root. One of:

- language server found → *"`<root>`: `<name>` — cross-file edges resolve."*
- tree-sitter only → *"`<root>`: tree-sitter — cross-file edges are heuristic;
  cross-file renames will defer."*
- none → *"`<root>`: ctags only — all edges heuristic; cross-file renames will
  defer."*

Name the consequence, not just the gap. A missing resolver is the one
`preferred` gap whose effect a user cannot guess from the tool's name, and
`observe.md` §9.3 is what turns it into deferred work rather than slower work.

Keep it to one line each. The report is a table plus a verdict, not a
narrative.

Do not restate the whole JSON in prose. The file is the artifact.

---

## What doctor does not decide

It does not decide whether a wave should run — only whether it *can*. Wave
sequencing remains a ledger question, gated by shards, and `doctor` has no
opinion about it.

It does not rank tools or recommend adoption. If a preferred tool is absent,
`doctor` records the gap; it does not argue for installing it.

It does not resolve stack ambiguity by judgment. A root whose manifests give
contradictory signals is recorded with `stack: null` and an `ambiguous` note,
and the human rules on it.
