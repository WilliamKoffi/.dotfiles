---
name: survey
description: Wave 0 of the refactor pipeline. Inventories the scope read-only and produces the ledger of findings. Modifies no code.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(git log *), Bash(git status *)
---

# Wave 0 — survey

Read-only **as to code**. You modify no code file. The only file you may write
is `trash/grain/ledger.json`.

`Write` and `Edit` are granted for that one path and no other. Without them this
wave cannot produce its own output; the grant is the mission, not an exception
to it.

## Input

Rulebooks loaded by the router. For each family present, read the sections of
every wave so you know what to look for.

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

For each problem detected, emit a finding **addressed to the wave that owns
it**. Propose no fix.

## Output

Create or update `trash/grain/ledger.json` at the project root:

    {
      "scope": "<scope>",
      "families": ["ecmascript", "php"],
      "findings": [
        { "id": "F-001", "wave": "slice", "family": "ecmascript",
          "kind": "naming", "path": "src/hooks/user-hook.ts",
          "note": "dash instead of dot", "status": "open" }
      ]
    }

A finding may carry extra fields specific to its owning wave — for example
`kind: "literal-cluster"`, opened by `domain` for the `literal` wave (see
`domain/SKILL.md`). `survey` never generates that `kind` itself: it does not
have the view of the concept a literal cluster represents; only `domain` does.

Sequential, stable identifiers. Never reuse a retired id.

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
- Every finding carries an owning wave and a family
- Extensions not covered by a rulebook are listed explicitly
- The symbol inventory (item 7) covered every extension in the family, and the
  per-extension count of symbol-level findings is reported
