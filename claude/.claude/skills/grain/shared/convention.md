# grain — Shared Convention

> Single source of truth for the `grain` skill suite.
> Every skill in `~/.claude/plugins/grain/skills/` reads this file.
> **Never restate these rules inside a SKILL.md.** Reference them by section number.

---

## §0. Precedence

When two rules collide, resolve in this order:

| Rank | Rule class | Beats |
|---|---|---|
| 1 | §6 Legacy red line | Everything |
| 2 | §5 Behavior preservation | Everything below |
| 3 | §1 Affordance placement | Naming, file size |
| 4 | §2 Naming | File size |
| 5 | §3 File structure | — |

If a rule cannot be satisfied without breaking a higher-ranked one, record it in
the ledger as `deferred` with a one-line reason. Do not silently drop it.

---

## §1. Affordances over Abilities

### 1.1 — Reject agent nouns
Classes named `Manager`, `Service`, `Handler`, `Broadcaster`, `Sender`,
`Processor`, `Coordinator`, `Helper`, `Util` are middlemen. Flag every one.

Exception: framework-mandated names (`ServiceProvider`, `RequestHandler` from an
interface you do not own). Record as `exempt:framework`.

### 1.2 — Method placement
Move a method to the object **holding the state**, not the object **performing
the action**.

```
❌ gardener.water(plant)      — ability
✅ plant.water()              — affordance
❌ user.redeemLicense(l)      — god object
✅ license.redeem(user)       — affordance
```

**Test:** if the method body mutates `other` more than `this`, it belongs on `other`.

### 1.3 — Missing concepts
A bloated controller/component does not need another Service. It needs a **noun**
— a domain object that owns the state. Extract `Checkout`, `Draft`, `Session`,
not `CheckoutService`.

### 1.4 — Stateless collections
If a module holds no state and only wraps side effects or native calls, it is not
a class. Use a namespace (TS), module (Python/Ruby), or static class (C#/Java).

```ts
export namespace Asset {
  export function ship() { }
}
// Asset.ship()
```

Invocations should read as English: `Asset.ship()`, `Store.read()`, `Invoice.send()`.

---

## §2. Naming

### 2.1 — Props and attributes: one English word

| ❌ | ✅ |
|---|---|
| `isOpen` | `open` |
| `isLoading` | `busy` |
| `handleClose` | `close` |
| `onInput` | `input` |
| `submitAction` | `submit` |
| `hasError` | `broken` / `invalid` |

### 2.2 — The one-word escape hatch
A compound name is permitted **only** when the one-word form is genuinely
ambiguous in that file's scope. Two conditions, both required:

1. The one-word form already means something else in the same scope, **and**
2. No better single word exists in English.

When you use the escape hatch, record `naming:compound` in the ledger with the
collision it avoids. Unrecorded compounds are violations.

### 2.3 — `set*` scope
`setX` is reserved **exclusively** for the setter half of a `[state, setter]`
pair (`useState`, signals, stores).

- Setter: always camelCase — `setReady`, `setOpen`
- A method that mutates without being a reactive setter is **not** `setX`.
  `invoice.setPaid()` → `invoice.pay()`. `door.setOpen()` → `door.open()`.

### 2.4 — Variables
No abbreviations. No acronyms except domain-standard ones (`url`, `id`, `http`).
Underscores only where a language idiom requires them.

### 2.5 — Files
`kebab-case.ts` for modules. `PascalCase.tsx` for components only.
The file name is the concept it exports — `measure.ts` exports measuring, not
`measureUtils.ts`.

---

## §3. File structure

### 3.1 — Size
Max **150 lines**. Over that, split.

### 3.2 — Split by role, not by type
When a file mixes concerns, split into a folder where each file is a **role**:

```
resize/
  measure.ts    ← the ruler
  listen.ts     ← the ear
  animate.ts    ← the mover
  index.ts      ← the composer
```

Not `types.ts` / `utils.ts` / `constants.ts` — those are types, not roles.

### 3.3 — `index` ruling
**`index` is a composer, never a barrel.**

- ✅ `index.ts` assembles the roles in its own folder into the public concept.
- ❌ `index.ts` that only re-exports siblings (`export * from './measure'`).

A folder whose `index` is a pure re-export means the folder was a false split —
collapse it back into one file, or give the index real composition work.

Root-level `src/index.ts` as an entry point is exempt.

---

## §4. Component boundaries

- A component that both fetches and renders has two jobs. Split the fetch upward.
- Props flow down. Events flow up. No prop drilling past two levels — extract
  context or move the state down.
- A component holding more than three pieces of local state is holding a domain
  object it hasn't named yet. See §1.3.

---

## §5. Behavior preservation

Every `grain` skill operates under one rule, uniform across the suite:

> **Observable behavior must not change.** Public API, rendered output, network
> calls, and side-effect ordering are identical before and after.

Consequences, binding on every skill:

- Renames of **exported** symbols require updating all call sites in the same pass.
- If a call site lives outside the argument path, the rename is **deferred**, not
  performed. Record `blocked:out-of-scope` in the ledger.
- No behavior fixes. If a skill finds a bug, it records it and moves on. A bug
  fix is a separate commit by a human.
- No dependency additions. No config changes.

---

## §6. The legacy red line

Do **not** touch, import from, or modify anything under `src/legacy/`.

Violations found there are recorded as `legacy:observed` and never acted on.
A skill that would need to edit a legacy file to complete a change must defer
the whole change instead.

---

## §7. The ledger

Every skill reads and writes `trash/ledger.json` at the repo root.

`trash/` is a working directory, never committed. Add to the repo's
`.gitignore` before the first survey:

```gitignore
trash/
```

A ledger that reaches a commit is a bug: it records a run, not a decision, and
it will conflict on every branch that touches the same scope. If `trash/` is
already tracked, `git rm -r --cached trash/` before continuing.

```json
{
  "stack": "typescript-react",
  "scope": "src/features/billing",
  "wave": "affordance",
  "findings": [
    {
      "id": "aff-004",
      "rule": "1.2",
      "file": "src/features/billing/charge.ts",
      "note": "InvoiceService.send mutates Invoice",
      "status": "open",
      "raised_by": "survey",
      "closed_by": null
    }
  ]
}
```

**Status values:** `open` → `closed` | `deferred` | `blocked` | `exempt`

**Contract:**
- Only `survey` may create findings from scratch.
- Every other skill may close, defer, or block findings **assigned to its own wave**.
- No skill may close a finding raised for a different wave.
- `drift` reads only; it never mutates status.
- A skill whose wave has zero open findings writes `"<wave>": "skipped"` and exits.

---

## §8. Wave order

```
 0        1       2        3         [·]         4          5       6        7        8
survey → slice → domain → literal → [cruddy] → affordance → boundary → split → lexicon → drift
  RO                                                                                      RO
```

Two waves are conditional and carry no number of their own — a repo may run the
pipeline end to end without either firing:

- `literal` fires only on families whose rulebook has a `## literal` section.
  Today that is `ecmascript` alone; php, rust and nim fold the same extraction
  into `domain`. See `rules/families.md`.
- `cruddy` fires only when `ledger.stack` matches `laravel` or `php` **and** at
  least one open finding carries a `C`-prefixed rule. A php repo with no
  controllers writes `"cruddy": "skipped"` and does nothing. See `crud.md` §C0.

Being skipped is a normal outcome for both, not a failure. `drift` must not
report a skipped wave as an unmet invariant.

`survey` is read-only (`allowed-tools: Read, Glob, Grep`). `drift` is read-only
**as to decisions** — it raises nothing and closes nothing — but it does hold
`Edit` and `git mv`, because it is the one wave allowed to re-place files that
waves 2–5 created mid-pipeline. That is its mission, not an exception to it.

All mutating waves are `disable-model-invocation: true`. `survey` and `drift`
are auto-invocable. Every wave declares `user-invocable: true` explicitly.

---

## §9. Tone

Corrections are kind and educational. Never show bad code without immediately
following it with the fix. If the code is already right, say so and say why.
Readability beats academic purity — when a rule would make code worse, note the
tradeoff and take the readable option, recording it as `exempt:readability`.
