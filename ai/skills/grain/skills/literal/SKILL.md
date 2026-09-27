---
name: literal
description: Wave 3 of the refactor pipeline. Extracts repeated string and numeric literals into named unions, at the concept location fixed by the `domain` wave. Renames no identifier and creates no file outside what `domain` designated.
argument-hint: [path]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Wave 3 — literal

Mission: **turn magic values into named members. Nothing else.**

This wave fires on findings only: it has no discovery mode. `domain` decided
*which* literals form a concept; you extract them. If
`trash/grain/roots/<root>/waves/literal.json` is absent or holds no open finding of
`kind: "literal-cluster"`, you have nothing to do —
report it and stop, without hunting for candidates yourself.

**Then say what you left behind.** Before reporting nothing to do — or reporting
any count at all — list every open finding on your shard grouped by `kind`, and
name every `kind` you did not fire on. You fire on `literal-cluster` alone, and
`survey` cannot emit that kind, so anything it noticed about repeated literals
is sitting in your shard under `defect` (`survey/SKILL.md`, `kind` vocabulary).
Those findings are not yours to re-shape — `domain` audits and re-raises them —
but they are yours to **surface**, because you are the only wave that opens this
file and sees them.

"3 findings closed" is true and misleading when six sit open beside them. Report
both numbers or neither.

You run after `domain` (wave 2) and before `affordance` (wave 4), for one reason
only: `boundary` (wave 5) will type props against the unions you emit. Inverting
the order pays for a second rewrite of every signature.

## Applicability

The `## literal` section of the relevant family's rulebook, in
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`. Some families already close the value set
in their own `domain` wave (see `rules/families.md`, the `literal` row) — for
them this wave is a no-op by construction: any `literal-cluster` finding you
meet in those families is a routing error by `domain`, not work to do here.
Report it, do not extract it.

## Preconditions

Stop and report if any of these fails:

1. `trash/grain/roots/<root>/ledger.json` — the manifest — exists.
2. `trash/grain/roots/<root>/waves/literal.json` exists and holds at least one finding with
   `kind: "literal-cluster"`, `status: "open"`. An absent shard is the skip
   signal: set `waves.literal.status` to `"skipped"` in the manifest and exit.
3. Every retained finding has a `home` that already exists on disk. If `domain`
   designated a `home` it did not create, do not create it in its place: reopen
   the finding with a note `"missing home"` and move to the next one.
4. Every retained finding's `path`, and every `sites[].path`, exists on disk.
   Wave 1 moves and renames files, and your shard was written before it ran. A
   path that does not resolve is **`blocked:stale`** — never a finding you close
   as no-longer-applicable. Set the status, note the path, and move on; §7.6
   makes repairing it the moving wave's duty, not a licence for you to guess a
   destination.

   The same rot reaches line coordinates, and those you cannot check. A `note`
   citing `file.ts:32` is wrong twice over once the file moved and an earlier
   wave inserted declarations above that line. Trust `sites[].range` — which
   step 3 verifies against the text — and never a coordinate in prose.

If invoked with a path, retain only the findings whose **every** `sites[].path`
falls under that path. A finding partially in the perimeter is ignored entirely,
never applied partially.

## Allowed perimeter

- adding or extending a type/constant declaration in the `home` designated by
  the finding
- replacing the literal's text, exactly at the `range` recorded in `sites[]`
- adjusting the type annotation of the parameter or field that directly receives
  the replaced literal, only if it is currently `string`, `number`, or absent
- adding the import of the emitted symbol

## Frozen

- creating any file outside the `home` that `domain` designated
- any portion of a file outside the recorded `range`s
- any signature beyond the annotation of the direct site
- any rename of an existing identifier (the `lexicon` wave)
- any edit to control flow, to a condition, or to the shape of an expression
- reordering or reformatting imports

## Behavior preservation: value identity

The runtime value of every emitted member must stay identical, byte for byte, to
the original literal. `"in_progress"` stays `"in_progress"`. Do not normalize
case, do not translate, do not "clean up" — that is `lexicon`'s job, later, on
the identifier, never on the value. A value-identity violation is a silent
production bug, not a typecheck error: that is why step 3 of the procedure is
strict.

## Numeric literals

Extract a numeric literal **only** if the finding lists it explicitly. Never go
hunting for magic numbers yourself: array indices, `0`, `1`, `-1`, HTTP status
codes in status-code position, and unit conversion factors are not concepts —
`domain` decides otherwise, not you.

## Procedure

For each open and applicable `literal-cluster` finding, in ledger order:

1. Read `home`. If the concept symbol already exists there, compare its member
   set to `members`. Extra existing members are accepted; missing members are
   added. Never rewrite the value of an existing member.
2. Emit or extend the declaration (see the emission form below).
3. For each entry in `sites`, re-read the file and check that the text at
   `range` still matches `value`. **If it no longer matches, skip that site and
   note it** — the ledger is stale, and a blind edit on a shifted range corrupts
   the file.
4. Replace with the reference to the member; add the import if absent.
5. Annotate the directly receiving parameter or field with the union type, if
   and only if the current annotation is `string`, `number`, or absent.
6. Update the finding: `status: "closed"` if fully applied, otherwise leave it
   `"open"`. Either way write `disposition` (`convention.md` §7.2) — what you
   emitted and where — and `skipped_sites[]` for every site you did not apply,
   each with its reason. Never append any of this to `note`.

   A finding closed with a non-empty `skipped_sites[]` is closed as to its
   decision and incomplete as to its application. Only the field says so, and a
   reader counting closures will not know otherwise.

7. **Record the residue.** A site list is a commitment, and an incomplete one
   silently caps what you are allowed to fix. Where you replace a literal and
   the same value appears again in the same file *outside* every recorded
   `range` — a `Record<Union, string>` key, a `?? 'formal'` default — you were
   right not to touch it, and the file is now visibly inconsistent.

   Append each occurrence to `coverage.json` as `kind: "out-of-perimeter"`
   (`convention.md` §7.4), with `why_missed` naming the range rule. Holding the
   perimeter is correct; letting the observation die with the run is not. The
   perimeter is what you may change — it was never what you may notice.

Apply findings one at a time, re-reading each file before editing: ranges within
a file shift as you go.

## Emission form (ecmascript)

`as const` plus a derived union. Never a TypeScript `enum`: it emits runtime
code, breaks `isolatedModules`/`erasableSyntaxOnly`, and types nominally against
the raw strings the API boundary still produces — which would force `boundary`
into pointless casts two waves later.

```ts
export const OrderStatus = {
  Pending: 'pending',
  Paid: 'paid',
  Shipped: 'shipped',
  Cancelled: 'cancelled',
} as const

export type OrderStatus = (typeof OrderStatus)[keyof typeof OrderStatus]
```

Case of the member keys: see the `## literal` section of the family's rulebook.
If that section is absent for the file's extension, skip the finding and note it
rather than guess.

### Non-exhaustive clusters

If the finding carries `exhaustive: false`, the value set is not provably closed
(values coming from an untyped source). Emit the widened form:

```ts
export type OrderStatus =
  | (typeof OrderStatusValues)[keyof typeof OrderStatusValues]
  | (string & {})
```

Leave the finding `open` with `note: "non-exhaustive, widened"`. The `drift`
wave will carry it as a known gap rather than a regression.

## Output

`convention.md` §7.6 governs. Your files: `waves/literal.json`, the
`waves.literal` key of the manifest, `events.jsonl` (open and close, `decision`
plane), `coverage.json`, `concerns/`, and `stale` on any `plan.json` entry whose
`from[]` you edited.

You may **raise** a finding on another wave's shard (`convention.md` §7.2) and
you may not close one there. Two cases arise here routinely:

- A site you skipped because the wave that owns it comes later — a prop
  re-spelling a subset of the concept belongs to `boundary`, which types props
  against the unions you emit and is the reason for this wave's position in the
  order. Raise it on `waves/boundary.json`, and note where the subset is already
  derivable (`keyof typeof FACETS`) rather than asking for a second concept.
- A new cross-layer import edge created by importing the emitted symbol into a
  layer that did not reach the `home` before. Raise it as `kind: "boundary"`;
  the architecture question is above this wave's perimeter, and precondition 3
  forbids you the clean fix of relocating the concept.

Emit no report file of your own beyond these.

A `literal-cluster` finding whose `home` is a file that does not yet exist
carries a `plan_id`: the plan entry names the file to create. This is the one
case where you create a file, and it is `domain`'s designation, not your choice
— see precondition 3. The `affordance` wave reads closed `literal-cluster` findings
to know which signatures now carry a union rather than a bare primitive.

## Fork precaution

Under `context: fork`, changes fall outside session checkpoints: a
value-identity violation here does not show up in the typecheck. This wave
cannot verify by itself that the tree is clean with the tools it holds
(`git status` is not in `allowed-tools`) — say so explicitly on the first line
of output: the caller must have committed before invoking this wave in fork
mode. Then continue.

## Exit gate

- Every retained `literal-cluster` finding is `closed`, or `open` with an
  explicit note — and every one carries a `disposition`
- No emitted member differs from its original literal
- No file created outside the `home`s designated by `domain`
- Every open finding on this shard is reported, grouped by `kind`, with every
  `kind` not fired on named
- No finding closed on the grounds that its `path` does not exist —
  `blocked:stale` instead
- Every same-value occurrence left outside a recorded `range` is an
  `out-of-perimeter` entry in `coverage.json`
- Typecheck green
- Test suite green with no test modified, or the clause recorded as
  **unsatisfiable** naming the missing runner (`convention.md` §5.1) — value
  identity is the one error class a typecheck cannot catch, so a run without
  tests must say so rather than let a green typecheck stand in
- Open and close events written to `events.jsonl`
- No file under `trash/grain/` written outside §7.6's table
