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

## Exit gate

- No anonymous return shape in scope
- No group of three or more correlated primitives in a signature
- Typecheck green
- Test suite green, with no test modified
- `domain` findings closed or justified
- Every ecmascript cluster of repeated literals has an open `literal` finding or
  a written exemption
