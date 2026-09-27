# Decisions

Decisions that hold across projects, written once, taken or skipped per project by the
`scaffold` skill (`../skills/scaffold/`). A project never links here: init copies the
chosen decisions into the project's `docs/decisions/`, so the project reads on its own.

## Layout

```
decisions/
├── README.md                 # this file: rules, format, register
├── archs/<arch>.yaml         # an architecture: which decisions it offers, which are pre-checked
└── systems/<system>/<ID>-<slug>.md
```

Systems (closed list; adding one is a decision in `agents/`):

| System | Prefix | Covers |
|---|---|---|
| agents | `AGT` | How agents and people record knowledge, work and decisions |
| language | `LNG` | Human language, naming and casing |
| stack | `STK` | Package manager, frameworks, repo shape |
| database | `DB` | Ids, columns, timestamps |
| money | `MNY` | Storage, sign, display |
| auth | `AUTH` | Sessions and tokens |
| payments | `PAY` | Gateways |
| testing | `TST` | Runners and layers |

## Rules

1. **One statement per file.** A decision is taken or skipped whole. A variant (pnpm or bun)
   is two decisions that list each other in `conflicts`.
2. **Never edited once locked.** A change is a new decision with `supersedes: <ID>`; the old
   one gets `status: superseded by <ID>` (the only edit allowed). Fixing a typo is fine.
3. **Ids never change or get reused.** `<PREFIX>-NNN`, numbered per system.
4. **`proven_in` is honest.** Each entry names a project and its local id, or a `path:line`.
   A decision no project has lived with stays `proposed`.
5. **Project-only choices stay in the project.** A decision lands here when a second project
   meets the same question, or the user says so.
6. **An arch owns what it offers; a decision owns its content.** A decision file never names
   the archs that use it.

## Decision file

```markdown
---
id: MNY-001
title: Money is an unsigned integer in the currency's smallest unit
system: money
status: locked            # proposed | locked | superseded by <ID> | retired
date: 2026-09-27
conflicts: []             # ids that cannot be taken together with this one
requires: []              # ids that must be taken too
supersedes: null
proven_in:
  - ka-cosmetics D5, D50
  - lmdl 005
---

## Decision
## Why
## Consequences
```

## Arch file

```yaml
id: laravel-nuxt
title: Laravel api/ + Nuxt web/
proven_in: [ka-cosmetics, lmdl]
decisions:            # offered in this order; true = pre-checked
  STK-003: true
  STK-001: true
  STK-002: false
```

## Register

| Id | Decision | System | Status | Proven in |
|---|---|---|---|---|
| [AGT-001](systems/agents/AGT-001-one-owner-per-fact.md) | One owner per fact; `AGENTS.md` is a map | agents | locked | ka D24, lmdl 007, intelli-resume ADR-020 |
| [AGT-002](systems/agents/AGT-002-decisions-are-superseded.md) | A decision is never edited, only superseded | agents | locked | lmdl, vente, workstation skill |
| [AGT-003](systems/agents/AGT-003-work-as-files.md) | Work is tracked as files in `tasks/`, problems in `findings/` | agents | locked | lmdl, intelli-resume ADR-025 |
| [LNG-001](systems/language/LNG-001-english-code-french-customer.md) | English everywhere except text the customer reads, in French | language | locked | lmdl `AGENTS.md` §5 |
| [LNG-002](systems/language/LNG-002-snake-case-data-keys.md) | Data keys are `snake_case` end to end | language | locked | lmdl, vente 003 |
| [STK-001](systems/stack/STK-001-pnpm.md) | pnpm is the package manager | stack | locked | lmdl |
| [STK-002](systems/stack/STK-002-bun.md) | Bun is the package manager and script runner | stack | locked | vente 004, intelli-resume ADR-002 |
| [STK-003](systems/stack/STK-003-api-and-web-apps.md) | Two applications: Laravel `api/`, Nuxt `web/` | stack | locked | ka D32, lmdl 001 |
| [STK-004](systems/stack/STK-004-vertical-feature-slices.md) | Code is organised as vertical feature slices | stack | proposed | vente 001 |
| [DB-001](systems/database/DB-001-ulid-primary-keys.md) | ULID primary keys | database | locked | ka, lmdl 003 |
| [DB-002](systems/database/DB-002-nullable-timestamps-over-booleans.md) | Nullable `*_at` timestamps over booleans | database | locked | ka, lmdl `conventions/principles.md` §2 |
| [MNY-001](systems/money/MNY-001-integer-smallest-unit.md) | Money is an unsigned integer in the smallest unit | money | locked | ka D5/D50, lmdl 005, intelli-resume ADR-024 |
| [MNY-002](systems/money/MNY-002-direction-is-an-enum.md) | The direction of money is an enum, never a sign | money | locked | ka D16, lmdl 006 |
| [MNY-003](systems/money/MNY-003-one-display-formatter.md) | Amounts are displayed through one shared formatter | money | locked | vente 005, lmdl `conventions/api-contract.md` |
| [AUTH-001](systems/auth/AUTH-001-sanctum-spa-cookie.md) | Sanctum SPA cookie, not API tokens | auth | locked | ka D34, lmdl 009 |
| [PAY-001](systems/payments/PAY-001-gateway-behind-an-interface.md) | Payment gateways sit behind one interface | payments | locked | intelli-resume ADR-024, ka D52 |
| [PAY-002](systems/payments/PAY-002-jeko.md) | Jeko Africa is the payment gateway | payments | locked | ka D52/D53, lmdl 036, intelli-resume ADR-024 |
| [TST-001](systems/testing/TST-001-playwright-end-to-end.md) | Playwright runs the end-to-end tests | testing | locked | ka D26, lmdl 008 |
