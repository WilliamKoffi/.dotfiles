---
name: vertical-slice-refactor
description: Apply Vertical Slice Architecture to structure codebase by feature instead of technical layer, simplify folder navigation, eliminate naming redundancy, and clean filesystem imports/exports.
---

# Skill: Vertical Slice Architecture & Filesystem Refactoring

You are a senior software architect responsible for restructuring this codebase without changing runtime behavior.

Your objectives are to:

- Apply a Vertical Slice Architecture.
- Make the project easier to navigate.
- Eliminate redundant naming.
- Enforce a consistent filesystem.
- Update every import/export automatically.
- Preserve runtime behavior.

## Non-Negotiable Rules

- NEVER change business logic.
- NEVER modify application behavior.
- NEVER rewrite implementations unless required to fix imports.
- Only move, rename and reorganize files and folders.
- Use `git mv` whenever possible.
- Update every affected import/export.
- Remove dead imports after refactoring.

---

# Core Philosophy

The filesystem should communicate the architecture.

Folders describe **where** something belongs.

Filenames describe **what** the thing is.

Never repeat information already expressed by the folder hierarchy.

---

# 1. Vertical Slice Architecture

Organize the project by feature instead of technical layer.

❌ Bad

```text
components/
hooks/
services/
schemas/
types/
```

✅ Good

```text
features/
    authentication/
    checkout/
    dashboard/
    profile/
```

Each feature owns everything it needs.

Example

```text
checkout/
    api/
    components/
    hooks/
    schemas/
    services/
    stores/
    types/
    utils/
```

Shared code should only exist when genuinely reused across multiple features.

---

# 2. Shared Code Rule

Only move code into a shared module when it has at least **three independent consumers**.

Otherwise keep it inside its slice.

Good

```text
shared/
    ui/
    lib/
    config/
    contracts/
```

Avoid feature-specific code inside shared folders.

---

# 3. File Naming Convention

There are only two valid naming patterns.

---

## Pattern A — Technical Artifacts

Technical artifacts keep their suffix.

Pattern

```text
[group]s/[name].[group].[ext]
```

Examples

```text
services/payment.service.ts
services/store.service.ts

hooks/user.hook.ts
hooks/session.hook.ts

schemas/login.schema.ts
schemas/payment.schema.ts

types/user.type.ts
types/store.type.ts

stores/cart.store.ts

validators/email.validator.ts

constants/app.constant.ts

queries/customer.query.ts

repositories/order.repository.ts
```

The suffix identifies the artifact type and should remain.

---

## Pattern B — UI Components

UI patterns belong to folders.

The filename should only contain the entity name.

❌ Bad

```text
components/user-card.tsx
components/product-card.tsx
components/payment-dialog.tsx
components/loading-modal.tsx
components/building-choice-step.tsx
components/profile-table.tsx
```

✅ Good

```text
components/
    cards/
        user.tsx
        product.tsx

    dialogs/
        payment.tsx

    modals/
        loading.tsx

    steps/
        building-choice.tsx

    tables/
        profile.tsx
```

The folder already communicates the UI pattern.

Do not repeat it.

---

# 4. Remove UI Naming Noise

Whenever a filename contains a UI pattern, move that pattern into the folder.

Recognized UI categories include:

```text
cards/
dialogs/
drawers/
forms/
inputs/
lists/
menus/
modals/
popovers/
selects/
sheets/
sidebars/
steps/
tables/
tabs/
timelines/
toolbars/
tooltips/
widgets/
badges/
avatars/
buttons/
checkboxes/
radios/
```

Examples

❌

```text
user-card.tsx
```

✅

```text
cards/user.tsx
```

---

❌

```text
welcome-step.tsx
```

✅

```text
steps/welcome.tsx
```

---

❌

```text
login-dialog.tsx
```

✅

```text
dialogs/login.tsx
```

---

❌

```text
loading-modal.tsx
```

✅

```text
modals/loading.tsx
```

---

# 5. Naming Rules

Every JavaScript and TypeScript filename must be

- lowercase
- kebab-case
- concise
- descriptive

Good

```text
payment.service.ts
user.hook.ts
login.schema.ts
user.type.ts

cards/user.tsx
dialogs/login.tsx
steps/welcome.tsx
```

Bad

```text
User.ts
userCard.ts
user_card.ts
CustomerOrderHistory.ts
```

---

# 6. Prefer Folder Hierarchy Over Long Filenames

Avoid encoding hierarchy into filenames.

❌

```text
checkout-payment-method-selector.tsx
```

✅

```text
checkout/
    payment/
        components/
            selectors/
                method.tsx
```

Folders communicate relationships.

---

# 7. Component Props

If a Props interface is only used inside one component, name it simply:

```ts
type Props = {}
```

Not

```ts
type UserCardProps = {}
```

If exported publicly, keep an explicit name.

---

# 8. Local Types

If a type is only used by one slice, keep it inside that slice.

Avoid giant global `types/` folders.

---

# 9. Barrel Files

Avoid barrel files by default.

❌

```ts
export * from "./components"
export * from "./hooks"
export * from "./services"
```

Do not generate barrel files unless they define a deliberate public API for a package.

Prefer direct imports.

---

# 10. Imports

After every rename:

- Update imports.
- Update exports.
- Remove dead imports.
- Remove dead exports.
- Remove duplicate imports.
- Preserve path aliases.

The project must compile without modification.

---

# 11. Preserve Runtime Behavior

This refactor must never:

- change logic
- change rendering
- change hooks
- change APIs
- change types
- change state management
- change tests

Only the filesystem organization changes.

---

# 12. Detect Architectural Smells

Automatically identify and improve:

- oversized `components/` folders
- oversized `hooks/` folders
- duplicated utilities
- duplicated hooks
- duplicated services
- duplicated schemas
- duplicated types
- generic `helpers`
- generic `utils`
- unnecessary nesting
- filename redundancy
- inconsistent naming
- feature code split across unrelated directories

---

# 13. Decision Rules

When multiple valid structures exist, choose the one that:

1. maximizes feature cohesion
2. minimizes filename redundancy
3. favors folders over filename prefixes/suffixes
4. keeps names short
5. avoids unnecessary nesting
6. minimizes future maintenance
7. improves discoverability
8. follows Vertical Slice Architecture

---

# 14. Final Report

At the end of the refactor, provide:

- The new project tree.
- Every file moved.
- Every file renamed.
- Every folder created.
- Every updated import.
- Architectural improvements performed.
- Remaining issues requiring manual review.

The codebase should compile exactly as before, with identical runtime behavior and a significantly cleaner, more discoverable filesystem.
