# Family ecmascript

Extensions: `.js`, `.jsx`, `.ts`, `.tsx`, `.vue`

## slice

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

- If several values always travel together, extract a domain name. Three or
  more correlated primitives in a signature = finding.
- Never an anonymous return shape (`{ tone: string; text: string }[]`).
  Declare and export a named interface.
- DTOs sharing a base -> interface inheritance (`Query extends Profile`).
- Ban `any` and `any[]`.
- A function with more than three arguments -> group them into a typed DTO.

## literal

- Member keys in PascalCase inside the `as const` object (`Pending`, `Paid`).
  The associated value stays the original literal, unchanged.
- Name of the exported concept: singular PascalCase (`OrderStatus`, not
  `OrderStatuses` nor `ORDER_STATUS`).
- Never a TypeScript `enum` — see the rationale in `literal/SKILL.md`.
- A cluster whose values already pass through an existing `as const` object is
  not a new finding: it is `domain` that should have attached it to the existing
  concept instead of opening a second one.

## affordance

- Remove agent nouns: `*Manager`, `*Service`, `*Handler`, `*Broadcaster`,
  `*Sender`, `*Engine`, `*Helper`, `*Util` carrying logic.
- Move the method to the object holding the state.
  `Gardener.water(plant)` -> `plant.water()`.
- God object: `user.redeemLicense()` -> `license.redeem(user)`.
- Stateless between calls -> `export namespace Domain { ... }` with pure
  functions. Stateful -> entity.
- Purge `get*` wrappers that encapsulate nothing.

## boundary

Applies to `.tsx`, `.jsx`, `.vue`. Not to pure modules.

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

- Inspection threshold: 150 lines. It is a **trigger for review**, not an order
  to split automatically.
- Split only on a real responsibility boundary. If the file is 180 lines of one
  coherent thing, leave it and record a written exemption.
- Typical cuts of a mixed module: `measure.ts` / `listen.ts` / `animate.ts` /
  `hook.ts`.
- Extract inline SVGs to `assets/`.
- Every file created here follows the naming convention in the `slice` section.

## lexicon

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

- No file off the `<entity>.<role>.<ext>` convention for a recognized role.
- No barrel reintroduced.
- No agent noun reintroduced.
- Files created by `domain`, `affordance`, `boundary` and `split` are placed and
  named per the `slice` section.
- Build green, typecheck green.
