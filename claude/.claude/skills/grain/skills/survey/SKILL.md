---
name: survey
description: Wave 0 of the refactor pipeline. Inventories the scope read-only and produces the ledger of findings. Modifies no code.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git log *), Bash(git status *)
---

# Wave 0 — survey

Read-only. **You modify no code file.** The only allowed output is
`trash/ledger.json`.

## Input

Rulebooks loaded by the router. For each family present, read the sections of
every wave so you know what to look for.

## Work on `$scope`

1. File tree, by extension and by family.
2. Dependency graph between directories. Report cycles.
3. Slice candidates: which files change together (`git log --name-only` over the
   last 200 commits).
4. Duplicated utilities, hooks, schemas, types.
5. Dead code: exports with no consumer.
6. Untouchable zones (`src/legacy/`, vendored, generated).

For each problem detected, emit a finding **addressed to the wave that owns
it**. Propose no fix.

## Output

Create or update `trash/ledger.json` at the project root:

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

## Exit gate

- No code file modified
- Every finding carries an owning wave and a family
- Extensions not covered by a rulebook are listed explicitly
