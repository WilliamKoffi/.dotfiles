---
name: blueprint
description: Brainstorm a new project, or one that hasn't been designed yet, from the idea up to its business facts, domain modules, architecture, database tables and project-specific decisions. The work is drafted in a phased playground under trash/playground/<slug>_blueprint/ and, once approved, promoted into docs/domain/, docs/architecture/ and docs/decisions/. Use when the user wants to brainstorm, design, plan or bootstrap a project, asks what its decisions, modules, database or stack should look like, or wants the knowledge base written before any code.
argument-hint: [project-slug] [one-line pitch] | load [project-slug]
---

# blueprint

Turns an idea into the knowledge base a project is built from: business facts, domain modules,
architecture, database and the decisions behind them. The brainstorm happens in a playground; the
repo's `docs/` only gets what the user approved.

Formats for every file are in [`references/formats.md`](references/formats.md). Read it before writing.

First argument is `load` → run `/playground load <slug>_blueprint`, then continue at the first
phase that is not 🟢. Otherwise follow steps 0–7.

## 0. Ground

- Target = the current directory. State it; don't ask.
- Read what already exists: `README.md`, `AGENTS.md`, `docs/`, `trash/playground/README.md`, the
  manifests (`composer.json`, `package.json`, `Cargo.toml`, …). An existing fact is an input, never
  something to re-ask.
- `docs/domain/` or `docs/architecture/` already filled → this is an update. Brainstorm only the
  gaps the user names, and never rewrite an approved doc wholesale.
- The user names a **source project** to reuse (the way lmdl came from ka-cosmetics) → read its
  `docs/` and schema. Mark each inherited fact `from <source>`, and later give it its own source.
- `trash/` not in `.gitignore` → say so, and offer to add it before writing.

## 1. Open the playground

`ctx` = `<slug>_blueprint`. Create it in the playground skill's **Phased** shape
(`~/.claude/skills/playground/SKILL.md` §2–4) and register it in `trash/playground/README.md`:

| Phase | Group | File |
|---|---|---|
| 01 | Business | `01_business.md` |
| 02 | Domain | `02_domain.md` |
| 03 | Architecture | `03_architecture.md` |
| 04 | Database | `04_database.md` |
| 05 | Decisions | `05_decisions.md` |
| 06 | Promote | `06_promote.md` |

Plus `events.md` (newest first) and `questions.md` (open questions, one checkbox each).
Write a phase file only when its phase starts. Don't leave empty files behind.

## 2. Business (phase 01)

Interview the user in rounds of at most 4 questions with AskUserQuestion. Each option is a concrete
proposal fitted to the pitch, with the recommended one first. Never ask an open "what do you
want?" when a sensible default can be proposed.

Cover, skipping whatever step 0 already answered:

1. **What and for whom**: the offer, the customers (B2C, B2B, internal), and the name.
2. **Market**: country, currency and its minor unit, tax rate, customer language, and legal
   duties such as invoicing law, consumer rights or data protection. Look up the legal facts
   (WebSearch) rather than assuming EU defaults, and cite each one with its date.
3. **Channels**: web, mobile, back office, point of sale, API for third parties.
4. **Money in**: how people pay, and which gateways work in that market.
5. **Out of scope**: list what similar products have that this one won't, and let the user cut.

Write `01_business.md`. Each answer becomes an `events.md` entry with **Finding / Impact /
Status**, dated. Then set the phase to 🟡 and ask for sign-off before moving on.

## 3. Domain (phase 02)

1. Propose the **modules** (bounded contexts) as one table: module, what it owns, and its main
   nouns. Lean on existing names (Identity, Catalog, Orders, Payments, Content, Settings, …), and
   group them per [`references/formats.md`](references/formats.md) § Domain.
2. For each kept module, draft its **lifecycle**: the status flow as a `text` block, who moves it,
   and the invariants (what can never be true). Write these down before any table exists.
3. Surface the hard questions as they appear (money direction, partial payments, cancellations,
   stock reservation, returns window, multi-tenant or not). Each one goes into `questions.md` with
   a proposed answer.
4. Ask the user which modules to keep, drop or defer. Ask about lifecycles only where you had
   to guess.

## 4. Architecture (phase 03)

1. **Stack.** Run `python3 ~/.claude/skills/scaffold/scripts/decisions.py stacks` and offer those
   first. A choice the shared base already covers is **not** a blueprint decision; it goes to
   `scaffold` in step 7. Only what the base lacks becomes a project decision.
2. **Shape.** Decide how many applications there are and where they live, how the modules map to
   folders, and the API surface: an endpoint table per module with its name, plus the auth model.
3. **Frontend**: rendering mode, pages and their data, and the design source if any. A wanted
   visual theme → point to `/patine`. Don't design it here.
4. **Infrastructure**: development, production and CI tables (engine, hosting, processes,
   scheduled jobs, backups). Check the hosting against what the stack needs (a queue worker, Node
   on the server, a persistent disk).

For each axis, offer 2–3 options with their trade-offs and a recommendation. One question per axis.

## 5. Database (phase 04)

1. Settle the **cross-cutting rules** first, as decisions: the id type, money storage (integer in
   the minor unit, never float), timestamps instead of booleans, the soft-delete policy, the naming
   rule, and enums vs lookup tables. When the shared base already holds one, cite it.
2. Then write **one table block per table**, grouped by module, in the format of
   [`references/formats.md`](references/formats.md) § Database. Every FK says what happens on
   delete. Every unique is explicit, or else the doc says where code checks it.
3. Check the schema against the domain: each lifecycle status has a column, each invariant has a
   constraint or a named code check, and no fact is stored twice. Optionally add a Mermaid
   `erDiagram` per module.
4. Write down what was set aside under `## Deferred`, with the reason and a "needed before"
   milestone.

Present the schema per module and let the user rename, add or cut. Their edits often come in
rounds. Log each round as an `Update YYYY-MM-DD (n)` on the same `events.md` entry.

## 6. Decisions (phase 05)

Collect every settled event into `05_decisions.md` as candidate decisions in the project format
([`references/formats.md`](references/formats.md) § Decision): title, the decision in one or two
sentences, why, and the consequences.

- **Source** = the `events.md` entry (`blueprint events.md "<heading>" (YYYY-MM-DD)`), or the user's
  answer.
- One decision per choice. Split one that mixes two choices.
- Generic decisions the shared base already holds are listed apart, as "take through `scaffold`".
- Show the full list as one table (`# | Decision | Source`) and get approval. Each decision can be
  kept, reworded or dropped.

## 7. Promote (phase 06)

Only after the user approves. Ask once, listing the files to be written.

1. **Shared decisions first.** No `docs/decisions/` yet, and the user wants the shared base →
   hand off to `/scaffold <stack>`. It refuses an existing register, so it must run before step 2.
2. **Project decisions.** Number them after the highest existing `NNN`, write
   `docs/decisions/NNN-<slug>.md` with status `locked`, and add the rows to the register in
   `docs/decisions/README.md`. Create that README in the lmdl format if it's missing.
3. **Knowledge.** Write `docs/domain/<module>.md` (business first) and
   `docs/architecture/{backend,frontend,database,infrastructure}.md`, whichever apply. Each fact
   has one owner: columns live only in `database.md`, and domain docs link to them. Decisions are
   cited by number (`decision 004`).
4. Each written file starts with a `> **State (YYYY-MM-DD):** designed, not built` line.
5. Write `06_promote.md` listing every file written and its source phase. Set all phases to 🟢 and
   refresh the README summary and the index row.
6. Offer the next step: `/workstation init` (tasks, findings, agents) when the project wants the
   protocol, or an implementation plan as a new playground phase.

Don't commit. Don't write application code or migrations. This skill only writes knowledge.

## Rules

- **The user decides; you propose.** Every question carries a recommended option. Record each
  answer with its absolute date.
- **No silent defaults.** An assumption you make goes into `questions.md` until confirmed. A guess
  never becomes a decision.
- **Verify external facts** (law, tax, gateway availability) and cite each with its date.
  Otherwise write "not verified".
- **Superseding, not editing.** Once promoted, a decision changes only by a new decision with
  `Supersedes: NNN`.
- Keep the phases in order, but loop back when a later phase breaks an earlier one: reopen it (🟡)
  and log why in `events.md`.
- Every reply is short: the phase, what changed, and the next question. Findings go in the files,
  not the chat.

## Report

At each pause: the phase and its status, the files touched, and the open questions.
After promotion: the files written in `docs/`, the decision numbers and the next step offered.
