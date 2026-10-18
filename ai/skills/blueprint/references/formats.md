# Formats

Modeled on `~/lab/dev/enterprises/dominium/lmdl/docs/` and its `trash/playground/lmdl_bootstrap_plan/`.
When the target already has `docs/`, its own format wins over this file.

## Playground

### `README.md`

```markdown
# 🧭 <Project> Blueprint

> **Context:** `<slug>_blueprint`
> **Location:** `./trash/playground/<slug>_blueprint/`
> **Target:** `<absolute path>`
> **Source project:** `<path>` (only when reusing one)

<One paragraph: the pitch, and that this tracks the design before any code.>

## 📊 Roadmap

| Phase | Group | Focus | Status | File |
|---|---|---|:---:|---|
| 01 | Business | Offer, market, channels, payments, out of scope | ⚪ Pending | [`01_business.md`](./01_business.md) |
| 02 | Domain | Modules, lifecycles, invariants | ⚪ Pending | [`02_domain.md`](./02_domain.md) |
| 03 | Architecture | Stack, applications, endpoints, frontend, infrastructure | ⚪ Pending | [`03_architecture.md`](./03_architecture.md) |
| 04 | Database | Cross-cutting rules, tables per module, deferred | ⚪ Pending | [`04_database.md`](./04_database.md) |
| 05 | Decisions | Candidate decisions, shared vs project | ⚪ Pending | [`05_decisions.md`](./05_decisions.md) |
| 06 | Promote | Files written to `docs/` | ⚪ Pending | [`06_promote.md`](./06_promote.md) |

Legend: ⚪ Pending · 🟡 In Review · 🛠️ In Remediation · 🟢 Approved

## Summary

- <current state, open items>
```

### `events.md`

```markdown
# Events

Newest first.

## <Short heading naming the choice>

- **Finding:** On YYYY-MM-DD the user <decided / answered / asked> ...
- **Impact:** <what it changes in the other phases>
- **Status:** decided | waiting on the user | deferred | dropped (YYYY-MM-DD)
- **Update YYYY-MM-DD (n):** <later revisions, appended; never rewrite the Finding>
```

### `questions.md`

```markdown
# Open questions

- [ ] **<topic>** — <question>. Proposed: <answer>. Blocks: phase NN.
- [x] **<topic>** — answered YYYY-MM-DD → events.md "<heading>".
```

## Domain

### `docs/domain/business.md`

```markdown
# Business

## <Name>

<What is sold or done, to whom, in which language.>

## Market (decision NNN)

| Fact | Value |
|---|---|
| Country | |
| Currency | <code>, <minor unit>, displayed `<example>` |
| Tax | |
| Payment | <methods, gateways> ([`payments.md`](payments.md)) |
| Legal | <invoicing law, consumer rights, data protection; source and date> |

## Design source

## Out of scope

<Comma-separated list of what is deliberately not built.>
```

### `docs/domain/<module>.md`

```markdown
# <Module>

Columns are in `docs/architecture/database.md`; <related module> is in [`<x>.md`](<x>.md).

## <Flow name>

1. **<Step>.** <who does what; which endpoint; which decision>.

## <Entity> lifecycle

```text
draft → confirmed → shipped → delivered
      ↘ cancelled
```

<Invariants. What is not decided yet, said plainly.>
```

Module table for phase 02:

| Module | Owns | Main nouns | Keep? |
|---|---|---|---|
| Identity | who can sign in, roles | user, admin, client | |
| Catalog | what is offered | product, category, variant | |
| Orders | from cart to delivery | order, item, delivery, return | |
| Payments | money in and out | payment, attempt, notification | |
| Content | editorial pages and media | page, banner, faq | |
| Settings | shop-wide values | setting | |

## Architecture

`backend.md`: a `## Folders` tree in a `text` block, a `## Endpoints` table
`Module | Endpoint | Name`, and the auth model.
`frontend.md`: rendering mode, pages table `Page | Route | Data | Source`.
`infrastructure.md`: `## Development`, `## Production`, `## Continuous integration`, each a
`Piece | Value` table (or `Job | Steps` for CI).

## Database

`docs/architecture/database.md` is the **sole owner of tables and columns**.

```markdown
# Database

**Sole owner of tables and columns** (decision NNN).

> **State (YYYY-MM-DD):** designed, not built.

## Rules

Every `id` is a <ULID>. Money is <unsigned bigint, minor unit>. <Soft deletes, naming rule.>

## <Module>

### `<table>` (<Module>)

| Column | Type | Notes |
|---|---|---|
| `id` | ulid PK | |
| `<parent>_id` | FK → <parents>, cascade | |
| `status` | enum `a`, `b`, `c` | lifecycle in `docs/domain/<module>.md` |
| `amount` | unsigned bigint | money, decision NNN |
| `paid_at` | timestamp nullable | |
| timestamps, `deleted_at` | | |

## Deferred

- `<table>` (<why>): needed before <milestone> (decision NNN).
```

## Decision

### `docs/decisions/NNN-<slug>.md`

```markdown
# NNN — <Title>

- **Status:** proposed | locked | superseded by NNN
- **Date:** YYYY-MM-DD
- **Source:** blueprint `events.md` "<heading>" (YYYY-MM-DD) | user request (YYYY-MM-DD)
- **Supersedes:** NNN (optional)

## Decision

<One or two sentences.>

## Why

## Consequences
```

### `docs/decisions/README.md` (only when missing)

```markdown
# Decisions

Why <Project> is the way it is. One file per decision: `NNN-<slug>.md`.

## Rules

- A locked decision is never edited. To change it, write a new decision with `Supersedes: NNN` and set the old
  one's status to `superseded by NNN` (the only edit allowed).
- Every decision names its `Source`.
- Check this register before any structural choice.

## Format

<the block above>

## Register

| # | Decision | Status | Source |
|---|---|---|---|
```
