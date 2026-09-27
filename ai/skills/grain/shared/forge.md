# forge.md

Doctrine for the forge, grain's one runtime accelerator. Cited by
`skills/survey/SKILL.md` and by `convention.md` §8d. Nothing here is restated
in a SKILL.md.

---

## §A Standing

The forge is a runtime accelerator per `convention.md` §8d — not a wave, not
a preflight, not a non-wave skill. It is the fourth artifact class, and the
only one whose absence makes a run slower rather than incomplete.

| | Ledger shard | `plan.json` | `capability.json` | `forge.json` |
|---|---|---|---|---|
| Created by | `survey` | `survey` | `doctor` | `survey` |
| Contains findings | yes | no | no | no |
| Absent means | skip that wave | plan un-precomputed | halt — probe not run | **go slower** — degrade to in-model |
| Freezes anything | yes, via `closed_by` | no | no | no |

`forge.json` is the only artifact in the row whose absence is neither a skip
signal nor a halt. Every other artifact class either means the pipeline does
less work or stops entirely; the forge missing means the pipeline does the
same work, at the same correctness, more slowly.

Owned by `survey`, because adoption happens at wave entry (§C) and `survey`
is wave 0 — there is no earlier point at which an engine could be selected.

## §B Stack agnosticism

The helper consumes normalised artifacts only — ctags JSON, path lists, grep
output, byte offsets. It NEVER parses language syntax.

This is the constraint that makes one binary correct for a Laravel root and a
Next.js root simultaneously. The moment it needs to read PHP it becomes five
binaries and a bad reimplementation of `ast-grep` — an accelerator that
understands syntax is a second parser to maintain per language, which is
exactly the cost this design avoids.

## §C The n / n+1 handoff

This is a warm cache, not a race. Bash calls within a wave are sequential and
blocking, so by the time a background build lands, the interpreted pass has
already answered `survey`'s question for *this* run. The value of a
compiled binary is realised on the **next** run, never the current one.

| Run sees `forge.json` as | Engine used | Background action |
|---|---|---|
| absent | python | build |
| validated, source hash matches, fingerprint matches | nim | nothing |
| validated, source hash differs | python | rebuild |
| validated, fingerprint differs | python | rebuild |
| quarantined | python | nothing — needs a human |

**Fingerprint differing is its own row, and it has to be.** `source_hash`
covers `forge/src/` and `forge/fixture/` (§H) — grain's own bytes, and
nothing about the compiler that turned them into a binary. A Nim point
upgrade produces a different binary from identical source, validated by a
fixture run that predates the upgrade. The capability fingerprint
(`capability.md` §8) is what notices, because it hashes the toolchain rather
than the input to it.

A rebuild is the whole remedy. There is no migration and no partial reuse —
`observe.md` §7.4's ruling applies here identically, and a binary is the
cheapest possible thing to rebuild.

**Engine is selected at wave entry and held for the whole wave.** No hot-swap
mid-pass. A wave may batch across hundreds of files, and a background build
can land in the middle of that batch, but the ledger has no field recording
which engine produced which finding — a split-engine run is unreconstructable
after the fact. Holding the engine fixed for the wave's duration is what
keeps a finding's provenance (§F) a fact about the run rather than a guess
about timing.

## §D Determinism

The fixture (§I) compares Python and Nim output byte for byte, so any
nondeterminism quarantines a **correct** binary and costs an afternoon of
debugging a phantom. The rules exist to make that never happen:

- `json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=True)`.
  Nim's default `$` on `JsonNode` spaces differently; both sides pin to one
  shape or nothing ever matches.
- No floats in output, ever. Python's `repr` and Nim's `formatFloat` disagree
  on the last digit. Integers, or fixed-precision strings.
- `sorted()` on every collection before emission. Never iterate a set, never
  rely on dict insertion order surviving a round trip.
- Sorting is one place the two languages agree: Python sorts `str` by
  codepoint, Nim sorts `string` by byte, and for valid UTF-8 those are the
  same order. Rely on it **deliberately** — and reject non-UTF-8 paths at the
  parse boundary rather than guessing.
- Repo-relative paths, forward slashes, no `realpath()`. Symlink resolution
  differs across platforms and yields a divergence that reproduces on one
  machine only.
- Nothing environmental in output: no wall clock, no pid, no cwd, no `$USER`.
  Set `PYTHONHASHSEED=0` as belt and braces.
- `\n` only. Open with `newline=""` or in binary.

## §E Delegation

The test: total, deterministic, verifiable, high fan-out, and carries no
doctrine branch.

Delegable today, both named with their doctrine reference:

- `survey` item 7's symbol inventory and fan-in counts (arithmetic over
  ctags records)
- `crud.md` §C9.8 condition 2's full-prefix literal-URL grep

**Named but not licensed:** an LSP client holding a stdio session for the
duration of a wave. `survey` Gate 0e rules that a resolver grain cannot invoke
in one shot is an absent resolver, precisely because a wave has no owner for a
long-lived subprocess. A compiled helper does — it starts the server, drains
it, and exits with the wave's own lifetime. This passes the delegation test on
every clause except *carries no doctrine branch*: an LSP result decides an
edge's `resolution` tier (`observe.md` §9.2), and that tier decides whether a
rename may run (§9.3). Resolve that before building it, not during.

The hard line: the helper may never author a finding's `note`, never resolve
a `judged` plan entry (`survey/SKILL.md` §8.1), never choose between two
branches doctrine leaves open. It computes; grain concludes. This is the
ctags precedent from `capability.md` §3 again — `required`, Ev `no`, it
indexes without opinion — and the helper stands in exactly the same relation
to the finding.

## §F Provenance

Every finding built on helper output is `source: "grain"`,
`confidence: "heuristic"`, permanently — however deterministic the helper is
and however much faster than a hand pass. See `convention.md` §7.2 for the
reasoning; it is not repeated here.

## §G Toolchain

**Python.** `uv` is mandatory. No bare-`python3` fallback. Launch line,
verbatim:

    uv run --script --no-python-downloads --offline <script>

`--no-python-downloads` is the flag that matters: it lets `uv` select any
conforming interpreter, managed or system, while never fetching one at
runtime, which is what keeps `doctor`'s "never installs" intact.
`--python-preference only-system` is **wrong** here — it would reject a
uv-managed interpreter a human deliberately installed via `remedy.sh`.
`--offline` is belt and braces; with `dependencies = []` there is no index to
hit in the first place.

PEP 723 header: `requires-python = ">=3.11"`, `dependencies = []`. `uv`
**refuses** on a wrong version rather than running — enforcement at launch,
not discovery mid-pass.

**Nim.**

    nim c -d:release --nimcache:trash/grain/forge/cache
          --out:trash/grain/forge/bin/<name>

Not `-d:danger`. It strips bounds checks, and a silent out-of-range read on a
fan-in table is precisely the divergence the fixture exists to catch. No
`.nimble` manifest — see `capability.md` §2 for why.

**If a KV is linked** (§K, `observe.md` §7.5), append `--passL:` naming the
static archive by absolute path — never `-llmdb`, which lets the linker pick a
shared object and silently produces the configuration §7.5 refuses. Then run
the linkage gate: the binary must show no KV library under `ldd`. A build that
fails the gate is discarded, not quarantined; quarantine is for a binary that
was validated and then disagreed (§I), and this one never ran.

**Stdlib only, both languages.** No `pip install`, no `nimble install`. This
inherits `doctor`'s "never installs" and is structural: a helper needing a
dependency is a helper that does not ship.

## §H forge.json schema

```jsonc
{
  "generated_at": "2026-08-14T10:02:11Z",
  "engine": "nim",
  "source_hash": "b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd",
  "fingerprint": "4b1d9e0c77a2f3518ac6d240be95713f",
  "python": { "resolved": "3.13.1", "via": "uv" },
  "nim": {
    "version": "2.2.6",
    "built_at": "2026-08-14T09:58:03Z",
    "binary": "trash/grain/forge/bin/fanin",
    "validated": true,
    "quarantined": false,
    "quarantine_reason": null
  }
}
```

| Field | Holds |
|---|---|
| `engine` | `python` \| `nim` \| `none` — the engine this run actually used |
| `source_hash` | hash over `forge/src/` AND `forge/fixture/` together |
| `fingerprint` | `capability.json.fingerprint` at build time (`capability.md` §8) |
| `python.resolved` / `python.via` | mirrors `capability.json.meta.python` at build time |
| `nim.validated` | true once the three-way check (§I) has passed for this binary |
| `nim.quarantined` | true if any check has ever failed for this `source_hash` |

`source_hash` is over `forge/src/` **and** `forge/fixture/` together — a
fixture change invalidates a binary as surely as a source change does, since
a binary validated against a stale fixture proves nothing.

## §I Validation

Three-way: interpreted output == binary output == fixture expected, byte for
byte. Any mismatch sets `quarantined: true` with a reason, and the binary is
never invoked again until a human clears it.

The fixture MUST include deliberately hostile input, not only a
representative sample: non-ASCII filenames, a path containing a newline, an
empty file list, a symbol with 5000 call sites. Those are exactly where
Python's forgiving semantics and Nim's strict ones part company, and a
happy-path fixture will pass while the pair silently disagrees in
production.

## §J The record

The forge emits `trace`-plane events (`observe.md` §2) for every invocation:
engine, duration, input byte count, and the hash of the argv it was launched
with. It emits a `decision` event on engine adoption and on quarantine.

**The argv is hashed, not recorded.** Parameters arrive as JSON on stdin
(`survey/SKILL.md`), so an argv holds paths and nothing else, and a path is
digested under `observe.md` §4 like every other path grain records. Hashing
the whole argv rather than digesting each element is sufficient here — the
question a trace answers is *was this the same invocation*, not *which files
were in it*.

**A quarantine is a decision event and not a finding.** `drift/SKILL.md`
already rules that a quarantined binary is not a finding and reports as a
gate line only; the event plane is where it is recorded, and `observe.md`
§2.3 is why it lands in `decision` rather than `trace`.

## §K Storage

The interpreted engine uses the filesystem CAS. The compiled engine may use
an embedded key-value store, under conditions stated once in `observe.md`
§7.5 and not repeated here.

The reason that split belongs to this file's design rather than being an
arbitrary line: it falls exactly along §C's engine boundary, which already
exists, is already selected at wave entry, and is already held for the whole
wave. A storage backend that changed mid-wave would reintroduce precisely the
split-engine unreconstructability §C exists to prevent.

The stdlib-only rule of §G is **not** waived for the KV, and §G's ban is on
**package managers at build and at run**, not on object code having an origin.
`observe.md` §7.5 states the linkage test that decides it, names the library
ruled out, and gives its own gate in §7.6.

One consequence lands in this file: a statically linked KV is inside the
binary, so `capability.md` §8.2's `binary_hash` over the forge binary already
covers its version. A dynamically linked one would need `doctor` to hash a
**library** — a probe class that does not exist and must not be created for
this. The linkage test is what keeps the fingerprint's shape unchanged.
