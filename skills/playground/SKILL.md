---
name: playground
description: Create or update a playground under trash/playground/<ctx>/ — a gitignored folder of notes that tracks one piece of work (a refactor, review, audit, diagnostic or design exploration) and is registered in trash/playground/README.md.
argument-hint: [ctx_slug] [what the playground tracks]
disable-model-invocation: true
---

# playground

Records the work of this session (or the topic in `$ARGUMENTS`) as notes under
`trash/playground/<ctx>/`, so a later session can pick it up cold.

`trash/` is gitignored. Never `git add` a playground, and never commit on its behalf.

## 1. Resolve the context

- `ctx` is snake_case, 2–3 words, named after the work, not the date:
  `product_resource_split`, `image_delivery_diagnostic`.
- First argument given → use it. Otherwise derive one from the conversation and
  state it in the reply; don't ask.
- `trash/playground/<ctx>/` already exists → **update** it (step 5). Never create
  `<ctx>_2`.
- Read `trash/playground/README.md` and one sibling of the same shape before writing,
  and match their tone and layout.

## 2. Pick a shape

| Work | Shape | Example |
|---|---|---|
| One task with steps, decisions and open questions (refactor, migration, skill build) | **Tracker**: `README.md`, `files.md`, `progress.md`, `log.md`, `events.md` | `product_resource_split/` |
| Many areas reviewed one by one (pages, modules, phases) | **Phased**: `README.md` roadmap table + `NN_<area>.md` per phase, `screenshots/` | `admin_reviews/`, `storefront_reviews/` |
| One finding or verdict (audit, root cause) | **Report**: a single `README.md`, extra files only for scripts or runbooks | `compliance_audit/`, `image_delivery_diagnostic/` |
| Competing designs to compare | **Variants**: `README.md` + `NN_<pattern>.<ext>` runnable drafts | `collection_enums/` |

Don't create a file that would be empty. A tracker without decisions has no `events.md`.

## 3. Write the files

**`README.md`** (every shape)
- `# <Title>`, then `> **Context:** \`<ctx>\``.
- One paragraph: what is tracked and why.
- Index table of the other files, with a one-line purpose each.
- Summary bullets: the current state, including anything still open.

**Tracker files**
- `files.md`: paths relative to `api/` or `web/`, grouped Moved / New / Modified / Deleted.
  One table row per file with the change.
- `progress.md`: `## Done`, `## Open`, `## Not started`, as `- [x]` / `- [ ]` checkboxes.
- `log.md`: numbered, chronological, most recent last. What was run and what it showed.
- `events.md`: newest first. One `##` per decision or finding, with **Finding**,
  **Impact**, **Status** (decided / waiting on the user / dropped).

**Phased files**: roadmap table `Phase | Group | Focus | Status | File`, plus the
status legend (⚪ Pending, 🟡 In Review, 🛠️ In Remediation, 🟢 Approved).

## 4. Register it

Add or update one row in the table in `trash/playground/README.md`:

```
| [**`<ctx>/`**](./<ctx>/README.md) | **<Title>**: <one sentence on scope and current state>. | [View Tracker](./<ctx>/README.md) |
```

Label: `View Tracker` (tracker, phased), `View Report` (report), `View Patterns` (variants).

## 5. Updating an existing playground

- Read every file in the folder first.
- Append to `log.md`; add new decisions to the top of `events.md`.
- Move closed items in `progress.md` to Done; set an event's **Status** when it's settled.
  Don't delete history.
- **Fix stale facts in place**: renamed files or skills, moved namespaces, questions
  answered since. A wrong note is worse than a missing one.
- Refresh the README summary and the index row.

## Rules

- **Verify before writing.** Every path, class, namespace, count and test result
  must be checked against the working tree or command output in this session. Write
  "not verified" rather than guess.
- Evidence goes inside the folder: screenshots in `<ctx>/screenshots/`, scripts in
  `<ctx>/`. Nothing lands in the repo root; delete any stray file you created there.
- Reference code as `path:line`; cite `AGENTS.md` and grain rules by section number
  (`§1.10`, `§3.2`) instead of restating them.
- Record user decisions with their date (absolute, `2026-09-14`).
- Notes only. Don't change application code while building a playground.

## Report

Reply with the folder path, the shape chosen, the files written or updated, the
index row, and any fact you couldn't verify.
