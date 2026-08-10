# Family ecmascript

Extensions: `.js`, `.jsx`, `.ts`, `.tsx`, `.vue`

**Extension scope.** Every wave section below opens with an `Applies to:` line.
A section without one applies to **all** family extensions. Absence of a scope
line is never a narrowing: a section that names no extension is not thereby
restricted to `.ts`. This line exists because a single scoped section
(`boundary`) once made every unscoped section read as belonging to the other
extension, and four waves swept `.ts` only for an entire run.

## slice

Applies to: all family extensions.

### Naming convention

    <entity>.<role>.<ext>

The technical role is separated from the entity by a **dot**, never by a dash.
The entity is kebab-case when it spans several words.

    hooks/user-hook.ts        ->  hooks/user.hook.ts
    services/payment-service.ts -> services/payment.service.ts
    cards/user-card.tsx       ->  cards/user.card.tsx
    dialogs/login-dialog.vue  ->  dialogs/login.dialog.vue
    steps/building-choice.tsx ->  steps/building-choice.step.tsx

This convention replaces the Pattern A / Pattern B duality. One single rule for
technical artifacts and for UI components alike.

**Deliberate redundancy.** The role appears both in the folder and in the
suffix (`cards/user.card.tsx`). That is intended: the folder serves navigation
through the tree, the suffix serves the editor tab, fuzzy-find, the stack trace
and `git log`. Do not "fix" this redundancy.

### Recognized roles

Technical:

    service hook schema type store validator constant query repository
    guard adapter mapper factory client config util

UI:

    card dialog drawer form input list menu modal popover select sheet
    sidebar step table tab timeline toolbar tooltip widget badge avatar
    button checkbox radio layout page view

A file whose role is not in this list keeps its bare name (`user.ts`). Do not
invent roles.

### Structure

- Vertical slice: `features/<feature>/` owns everything it needs.
- `shared/` only from **three** independent consumers onward.
- The category folder is the plural of the role: `cards/`, `hooks/`.
- Graphic assets go in `assets/` (`choice/assets/papers.tsx`).
- `index.tsx` that renders JSX = composer, allowed.
- `index.ts` that only re-exports = barrel, forbidden.
- Path aliases preserved. Dead imports removed.

### The `.vue` case

Same convention. An SFC has no resolution constraint, so `login.dialog.vue` is
safe. If the project uses component auto-import (Nuxt,
`unplugin-vue-components`), check that the resolver tolerates dots before
renaming: otherwise record a blocked `slice` finding rather than break
resolution.

## domain

Applies to: all family extensions. A `.tsx` file holds types,
signatures and return shapes exactly as a `.ts` file does.

- If several values always travel together, extract a domain name. Three or
  more correlated primitives in a signature = finding.
- Never an anonymous return shape (`{ tone: string; text: string }[]`).
  Declare and export a named interface.
- DTOs sharing a base -> interface inheritance (`Query extends Profile`).
- Ban `any` and `any[]`.
- A function with more than three arguments -> group them into a typed DTO.

## literal

Applies to: all family extensions.

- Member keys in PascalCase inside the `as const` object (`Pending`, `Paid`).
  The associated value stays the original literal, unchanged.
- Name of the exported concept: singular PascalCase (`OrderStatus`, not
  `OrderStatuses` nor `ORDER_STATUS`).
- Never a TypeScript `enum` — see the rationale in `literal/SKILL.md`.
- A cluster whose values already pass through an existing `as const` object is
  not a new finding: it is `domain` that should have attached it to the existing
  concept instead of opening a second one.

## affordance

Applies to: all family extensions.

- Remove agent nouns: `*Manager`, `*Service`, `*Handler`, `*Broadcaster`,
  `*Sender`, `*Engine`, `*Helper`, `*Util` carrying logic.
- Move the method to the object holding the state.
  `Gardener.water(plant)` -> `plant.water()`.
- God object: `user.redeemLicense()` -> `license.redeem(user)`.
- Stateless between calls -> `export namespace Domain { ... }` with pure
  functions. Stateful -> entity.
- Purge `get*` wrappers that encapsulate nothing.

## boundary

Applies to: `.tsx`, `.jsx`, `.vue` only. Not to pure modules — a module with no
render boundary has no props to compress. This is the one narrowed section in
this rulebook; it narrows nothing but itself.

- The parent holds the business state. The component holds the presentation
  state.
- Forbidden as props: `setX`, `showX`, `openX`, `toggleX`, and any
  `open`/`close` pair crossing a boundary.
- Interaction state is internalized in a local hook (`usePicker()`).
- Mandatory sequence, in this order:
  detect repeated primitives -> extract the name -> reduce the props ->
  internalize the UI state. Splitting comes later, in the `split` wave.
- One prop = one affordance. `upload`, `submit`, `close`, `back`, `choose`.

## split

Applies to: all family extensions.

- Inspection threshold: 150 lines. It is a **trigger for review**, not an order
  to split automatically.
- Split only on a real responsibility boundary. If the file is 180 lines of one
  coherent thing, leave it and record a written exemption.
- Typical cuts of a mixed module: `measure.ts` / `listen.ts` / `animate.ts` /
  `hook.ts`.
- Extract inline SVGs to `assets/`.
- Every file created here follows the naming convention in the `slice` section.

### `hub-in-leaf`

A **leaf** file composes: it arranges what others supply. A symbol inside a leaf
that supplies rather than arranges is in the wrong file, however large or small
its host.

Leaf roles — this list is literal and is **not** derivable from the recognized
role list above, which encodes no leaf/composer property:

    view tab page layout card step modal dialog drawer sheet sidebar

Deliberately excluded: `list`, `table`, `timeline`, `toolbar`, `widget`. Each is
often genuinely self-contained. On a first run, under-firing beats a wall of
false positives.

**Triggers.** Either one is sufficient:

1. Intra-file fan-in ≥ 5 — any file, any role, leaf or not. The candidate must
   be a **module-level** declaration, as enumerated by `survey` item 7: an
   export, a plain function declaration, or a const-arrow binding. Role is not a
   filter; scope is. A helper nested inside another function body is local by
   construction and is never a hub, whatever its fan-in.
2. Hosted in a leaf-role file **and** passing the structural qualifier below.

**What counts as fan-in.** Every reference to the symbol inside its host file:
direct calls, prop passes, arguments, and any binding into another structure.
Not the declaration itself.

A prop pass is not a weaker edge than a call — it is a stronger one. A symbol
called three times in its own file is a local helper. A symbol handed to nine
children is an interface, and an interface declared inside a leaf file is the
definition of misplacement. Counting only direct calls inverts the evidence and
will silently under-fire on exactly the hubs worth catching.

Fan-in is counted at the host file only. Transitive call sites inside the
children are not counted here; they are the blast radius the finding reports,
not the trigger.

**Structural qualifier** (trigger 2 only). The symbol must also do at least one
of:

- perform I/O — network, storage, database client
- mutate state outside its own component
- be called from more than one component in the file

A pure formatting or rendering helper with high fan-in is **not** a hub. It is
local convenience, and extracting it makes the code worse. This qualifier exists
to stop the wave firing on every `formatLabel` in the tree.

**The qualifier cannot cover trigger 1.** Its clauses are component-shaped —
*outside its own component*, *more than one component in the file* — and do not
translate to a module with no render boundary. Trigger 1 therefore stands
unqualified, and the module-level scope requirement above is the only thing
keeping it honest. A trigger-1 finding on a `.ts` module deserves a second look
before anyone acts on it.

**Owner: `split`, not `slice`.** `slice` moves and renames whole files; it
cannot lift a function out of a body. `split` already performs exactly this
operation. A finding of this kind that reaches `slice` is misfiled.

**Duplication check.** A live inline implementation duplicating a dead utility of
near-identical name is a `duplication` finding, not merely `hub-in-leaf`. The
resolution is to decide which of the two survives — extracting the live copy and
keeping both is the wrong answer.

**A cluster of hubs is one finding, not many.** When several hubs in a feature
mutate the same state, they are symptoms of one unnamed owner, not independent
misplacements. Name the owner first — that is `domain`'s work, wave 2 — and most
of the cluster stops being a hub, because each member becomes a method on the
thing that holds the state. Extracting them individually at wave 6 first means
redoing every one of them afterwards. The wave order already enforces this;
leave such findings where they are filed and do not start at `split` because the
`hub-in-leaf` count looks larger.

## lexicon

Applies to: all family extensions. Identifiers inside a component file
are in scope, not only its props.

Identifier renaming only.

- Props: one English word. A compound `<qualifier><noun>` is tolerated when the
  bare noun is ambiguous (`activeTab` yes, `active` no). `<verb><noun>` and
  `is<X>` are forbidden as props.
- Banned prefixes: `handle*`, `on*`, `callback*`, `trigger*`, `execute*`,
  `process*`, `is*`.
- Banned suffixes (leaking memory structure or metadata):
  `*Set`, `*Pool`, `*Tag`, `*Flags`, `*Meta`, `*List`, `*Array`.
- Local `useState` setter: `setX` in camelCase. **Mandatory, not a smell.**
  The `setX` ban covers public props, not local setters.
- Raising the vocabulary: `position` -> `role`, `company` -> `employer`,
  `isRemote` -> `remote`, `selectedSet` -> `chosen`, `isFr` -> `french`.
- No abbreviations, no acronyms.
- File name: lowercase, kebab-case for the entity.

## drift

Applies to: all family extensions.

- No file off the `<entity>.<role>.<ext>` convention for a recognized role.
- No barrel reintroduced.
- No agent noun reintroduced.
- Files created by `domain`, `literal`, `affordance`, `boundary`, `split` and
  `lexicon` are placed and named per the `slice` section. Every mutating wave is
  listed here; a wave absent from this list creates files nothing checks.
- Build green, typecheck green.
