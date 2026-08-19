---
name: domain
description: Wave 2 of the refactor pipeline. Creates the missing domain names and makes every shape explicit. Moves and renames no file.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Wave 2 — domain

Mission: **the concepts the code manipulates without naming them get a name.**

## Allowed perimeter

- new files for types, interfaces, structs, enums, value objects
- type annotations on existing signatures
- DTO hierarchies
- replacing correlated primitives with the extracted name, at the call sites

## Frozen

- file paths and names (wave 1 settled them)
- method placement (wave 4)
- existing identifier names (wave 7)
- runtime behavior
- repositories, DAOs, query objects: do not create any. When the extraction
  surfaces query logic that belongs behind a shelf, open a finding with
  `kind: "repository"`, list the call sites, and leave it `open`. `shelved`
  closes it.

## Rules

The `## domain` section of each family's rulebook, in
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

Every file created here follows the naming convention established in wave 1 for
its family. You do not re-decide the convention, you consult it.

## Signals

- three or more correlated primitives in a signature
- anonymous return shape
- closed set of values modeled as multiple booleans or as strings
- evasive typing

## Repeated literals: findings for wave 3

Some families close the set of values themselves (PHP `enum`, Rust `enum`, Nim
`enum` — see the `## domain` section of their rulebook). For those families,
delegate nothing: you already extract everything here.

For families whose rulebook has no dedicated native enum mechanism in
`## domain` (ecmascript today), a cluster of repeated literals is **not** yours
to extract — it is a finding you open for the `literal` wave:

    {
      "id": "F-014", "wave": "literal", "family": "ecmascript",
      "kind": "literal-cluster", "status": "open",
      "concept": "OrderStatus", "home": "src/orders/types.ts",
      "path": "src/orders/types.ts",
      "raised_by": "domain",
      "members": ["pending", "paid", "shipped", "cancelled"],
      "exhaustive": true,
      "sites": [
        { "path": "src/orders/api.ts", "range": [42, 51], "value": "pending" }
      ]
    }

`home` must be a path that already exists or that is the domain name *you* are
creating in this very wave — never a path `literal` would have to invent.
`exhaustive: false` if the value set is not provably closed (e.g. values coming
from an untyped API). You alone decide whether two identical strings are one
concept or two coincidences — `literal` never reopens that judgment, it only
extracts.

**`path` carries the same value as `home`.** `convention.md` §7.2 makes `path`
mandatory on every finding whatever else it carries. `home` stays authoritative
for `literal`; `path` is what every path-keyed sweep in the suite reads,
including the staleness check of §7.6. Omit it and these findings are invisible
to all of them, and read as `null` — indistinguishable from a stale path that
resolved to nothing.

### Audit the shard you inherit

Before you file anything, read **every** open finding already on
`waves/literal.json` and check its `kind`.

`survey` cannot emit `literal-cluster` — it does not have the view of the
concept a cluster represents, and says so. So anything it noticed about repeated
literals is sitting there under a `kind` that wave does not fire on, most often
`defect`. `literal` fires on `literal-cluster` alone; it will report "nothing to
do" and be telling the truth.

You are the only wave that can see both the shard and the concept. For each
mis-kinded finding, either:

- **raise** a correctly shaped `literal-cluster` finding (`convention.md` §7.2,
  "Raising") with `concept`, `home`, `path`, `members`, `exhaustive` and
  `sites[]`, cross-referencing the original in its `note`; or
- leave it, and say in your report why it is not literal work.

Do not re-`kind` the original in place — it is not yours to mutate
(`convention.md` §7.2). It stays for `drift` to count.

A banned construct is the case to watch. Where a family's rulebook bans a
construct outright — a TypeScript `enum` — a finding describing one is not a
`defect` to be reported forever; it is the largest piece of literal work in the
file, filed in the one bucket nothing ever opens.

**Values that cross a persistence boundary need a note.** Where a cluster's
values are serialized into a URL, written to `localStorage`, or stored in a
database, say so in the finding. `literal`'s value-identity rule already
protects them byte for byte, but the migration around them is wider than the
usual case, and the wave should know before it starts rather than after.

## Output

`convention.md` §7.6 governs. Your files: `waves/domain.json`, the
`waves.domain` key of the manifest, `events.jsonl` (open and close, `decision`
plane), `coverage.json`, `concerns/`, `stale` markers, and findings **raised**
on `waves/literal.json` and `waves/shelved.json` per §7.2.

Write `disposition` on every finding you close — one or two sentences on what
you did, or why you did nothing. Never append it to `note`; `note` is the
problem statement and stays as raised.

**A new cross-layer import edge is a fact you must record.** Tightening a type
by importing it from another layer — an `api/ → i18n/` edge, a `features/ →
api/` edge — is often the right call and is not yours to settle: architecture
above this wave's perimeter belongs to `boundary`. Raise the edge as a
`kind: "boundary"` finding on `waves/boundary.json` so wave 5 confirms or
rejects it deliberately. `dependency-cruiser` is `preferred`, not `required`
(`capability.md` §3), so on a degraded run nothing automated will surface it and
this finding is the only thing that will.

## Exit gate

- No anonymous return shape in scope
- No group of three or more correlated primitives in a signature
- Typecheck green
- Test suite green with no test modified, or the clause recorded as
  **unsatisfiable** naming the missing runner (`convention.md` §5.1)
- `domain` findings closed or justified, each with a `disposition`
- Every ecmascript cluster of repeated literals has an open `literal` finding or
  a written exemption
- Every open finding on `waves/literal.json` has been read and its `kind`
  judged — re-raised correctly shaped, or reported as not literal work
- Every finding you raised carries `path`, `raised_by`, and `status: "open"`
- Every new cross-layer import edge is raised on `waves/boundary.json`
- Open and close events written to `events.jsonl`
- No file under `trash/grain/` written outside §7.6's table
