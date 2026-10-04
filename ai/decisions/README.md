# Decisions

Conventions reused from one project to the next, written once, taken or skipped per project
by the `scaffold` skill (`../skills/scaffold/`). A project never links here: init copies the
chosen decisions into the project's `docs/decisions/`, so the project reads on its own.

## Layout

```
decisions/
├── README.md                 # this file: rules, format, register
└── systems/
    ├── <system>/<ID>-<slug>.md               # holds for any language or framework
    ├── <language>/<ID>-<slug>.md             # holds for that language, any framework
    └── <language>/<framework>/<ID>-<slug>.md # holds only with that framework
```

A decision that names a framework's files, classes or config lives in that framework's
folder under its language; one that holds on any stack lives in a system folder. The
`system` field is the folder path (`money`, `php`, `php/laravel`).

There are no preset stacks. `scaffold` asks which languages and frameworks a project uses,
then offers every generic decision plus those of the chosen folders. A top-level folder
counts as a language once it holds a framework folder; until then its decisions would be
offered to every project.

Systems and frameworks (closed list; adding one is a decision in `agents/`):

| System | Prefix | Covers |
|---|---|---|
| agents | `AGT` | How agents and people record knowledge, work and decisions |
| language | `LNG` | Human language, naming and casing |
| stack | `STK` | Package manager, frameworks, repo shape |
| database | `DB` | Ids, columns, timestamps, once-only claims |
| money | `MNY` | Storage, sign, display |
| payments | `PAY` | Gateways, webhooks, reconciliation, attempts |
| commerce | `COM` | Orders, checkout, cart, stock, coupons, delivery, returns, invoices, reports |
| marketing | `MKT` | Newsletter, campaigns, consent |
| ops | `OPS` | Production processes, health, backups, logs |
| security | `SEC` | Standing rules every surface follows |
| support | `SUP` | Post-sale customer support |
| testing | `TST` | Runners and layers |
| php/laravel | `LRV` | Laravel layout, routing, roles, auth (also holds STK-003 and AUTH-001, moved with their ids) |
| php | `PHP` | PHP code shape that holds on any framework |
| php/pest | `PST` | Pest test layout |
| ts/nuxt | `NXT` | Nuxt rendering and plugins |
| rust | `RST` | Rust code shape that holds on any framework (AGT-005) |
| rust/axum | `AXM` | axum HTTP layer (AGT-005) |
| rust/sqlx | `SQX` | sqlx queries and database tests (AGT-005) |
| rust/sea-query | `SQY` | Schema written with sea-query (AGT-005) |

## Rules

1. **One statement per file.** A decision is taken or skipped whole. A variant (pnpm or bun)
   is two decisions that list each other in `conflicts`.
2. **Never edited once locked.** A change is a new decision with `supersedes: <ID>`; the old
   one gets `status: superseded by <ID>` (the only edit allowed). Fixing a typo is fine.
3. **Ids never change or get reused.** `<PREFIX>-NNN`, numbered per system. A decision moved to another folder keeps its id.
4. **Abstract, never tied to a project.** A decision states a convention in its own words:
   no project name, no local id, no `path:line` into a project. Where an idea was first met
   is history, and stays out of the base.
5. **Only reusable conventions.** A choice that belongs to one product (a page, a business
   rule) stays in that product. A convention lands here when the user says so.
6. **A decision owns its content, not its audience.** It never names the projects or stacks
   that take it; its folder alone says which language or framework it belongs to.
7. **A decision never pairs frameworks or languages.** It holds for one system, language or
   framework on its own. Which ones a project combines is chosen when its stack is chosen
   (`scaffold`, §2), never written as a decision.

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
---

## Decision
## Why
## Consequences
```

## Register

| Id | Decision | System | Status |
|---|---|---|---|
| [AGT-001](systems/agents/AGT-001-one-owner-per-fact.md) | One owner per fact; AGENTS.md is a map | agents | locked |
| [AGT-002](systems/agents/AGT-002-decisions-are-superseded.md) | A decision is never edited, only superseded | agents | locked |
| [AGT-003](systems/agents/AGT-003-work-as-files.md) | Work is tracked as files in tasks/, problems in findings/ | agents | locked |
| [AGT-004](systems/agents/AGT-004-blocking-phase-gates.md) | Each phase ends with a blocking gate | agents | locked |
| [AGT-005](systems/agents/AGT-005-rust-systems.md) | Rust gets a language folder and three framework folders | agents | locked |
| [LNG-001](systems/language/LNG-001-english-code-french-customer.md) | English everywhere except text the customer reads, in French | language | locked |
| [LNG-002](systems/language/LNG-002-snake-case-data-keys.md) | Data keys are snake_case end to end | language | locked |
| [LNG-003](systems/language/LNG-003-ship-existing-languages.md) | Ship only the languages the content exists in | language | locked |
| [LNG-004](systems/language/LNG-004-one-word-type-names.md) | Models and enums are named in one word | language | locked |
| [STK-001](systems/stack/STK-001-pnpm.md) | pnpm is the package manager | stack | locked |
| [STK-002](systems/stack/STK-002-bun.md) | Bun is the package manager and script runner | stack | locked |
| [STK-004](systems/stack/STK-004-vertical-feature-slices.md) | Code is organised as vertical feature slices | stack | proposed |
| [STK-005](systems/stack/STK-005-separate-app-styling.md) | Storefront and admin styling never mix | stack | locked |
| [STK-006](systems/stack/STK-006-independent-modules.md) | Modules never compose each other's pages | stack | locked |
| [STK-007](systems/stack/STK-007-bin-by-slice.md) | Scripts live in `bin/<slice>/<word>.sh` | stack | locked |
| [DB-001](systems/database/DB-001-ulid-primary-keys.md) | ULID primary keys | database | locked |
| [DB-002](systems/database/DB-002-nullable-timestamps-over-booleans.md) | Nullable *_at timestamps over booleans | database | locked |
| [DB-003](systems/database/DB-003-sqlite-dev-mariadb-prod.md) | SQLite in development and tests, MariaDB in production | database | locked |
| [DB-004](systems/database/DB-004-atomic-claim.md) | A once-only side effect claims a timestamp first | database | locked |
| [DB-005](systems/database/DB-005-short-table-and-column-names.md) | Table and column names are the shortest clear noun | database | locked |
| [MNY-001](systems/money/MNY-001-integer-smallest-unit.md) | Money is an unsigned integer in the currency's smallest unit | money | locked |
| [MNY-002](systems/money/MNY-002-direction-is-an-enum.md) | The direction of money is an enum, never a sign | money | locked |
| [MNY-003](systems/money/MNY-003-one-display-formatter.md) | Amounts are displayed through one shared formatter | money | locked |
| [PAY-001](systems/payments/PAY-001-gateway-behind-an-interface.md) | Payment gateways sit behind one interface | payments | locked |
| [PAY-002](systems/payments/PAY-002-jeko.md) | Jeko Africa is the payment gateway | payments | locked |
| [PAY-003](systems/payments/PAY-003-webhook-ingestion.md) | Webhooks are stored raw first, upserted on gateway and reference | payments | locked |
| [PAY-004](systems/payments/PAY-004-reconciliation.md) | A scheduled command reconciles pending payments | payments | locked |
| [PAY-005](systems/payments/PAY-005-payment-attempts.md) | One payment per order, one attempt per try | payments | locked |
| [PAY-006](systems/payments/PAY-006-gateway-hardening.md) | Gateway calls fail closed | payments | locked |
| [COM-001](systems/commerce/COM-001-subtotal-and-adjustments.md) | An order stores subtotal and total; every other line is an adjustment | commerce | locked |
| [COM-002](systems/commerce/COM-002-frozen-total.md) | The order total is fixed at placement and never edited once paid | commerce | locked |
| [COM-003](systems/commerce/COM-003-guest-orders.md) | A guest order is a normal order | commerce | locked |
| [COM-004](systems/commerce/COM-004-minimal-public-lookup.md) | The public order lookup returns minimal personal data | commerce | locked |
| [COM-005](systems/commerce/COM-005-checkout-is-a-draft-order.md) | Checkout is a draft order | commerce | locked |
| [COM-006](systems/commerce/COM-006-one-draft-per-cart.md) | At most one draft order per cart; old drafts are pruned | commerce | locked |
| [COM-007](systems/commerce/COM-007-stock-at-placement.md) | Stock is taken at placement and returned only by cancel | commerce | locked |
| [COM-008](systems/commerce/COM-008-guest-cart-token.md) | A guest cart is keyed by a token, not the session | commerce | locked |
| [COM-009](systems/commerce/COM-009-coupon-redemptions.md) | Coupon usage is counted from redemptions | commerce | locked |
| [COM-010](systems/commerce/COM-010-delivery-methods.md) | Delivery methods are a table; price and carrier cost stay apart | commerce | locked |
| [COM-011](systems/commerce/COM-011-account-only-lists.md) | Wishlist and comparison are stored only for accounts | commerce | locked |
| [COM-012](systems/commerce/COM-012-returns.md) | Returns are their own module, with manual gateway refunds | commerce | locked |
| [COM-013](systems/commerce/COM-013-one-stock-authority.md) | One module owns stock, and every change is a movement | commerce | locked |
| [COM-014](systems/commerce/COM-014-immutable-invoices.md) | Invoices are immutable snapshots issued once per paid order | commerce | locked |
| [COM-015](systems/commerce/COM-015-paid-confirmation-invoice.md) | A receipt at placement, a confirmation with the invoice at payment | commerce | locked |
| [COM-016](systems/commerce/COM-016-cost-snapshots.md) | Order lines snapshot the unit cost; reports count paid orders only | commerce | locked |
| [MKT-001](systems/marketing/MKT-001-single-opt-in.md) | Newsletter sign-up is single opt-in | marketing | locked |
| [MKT-002](systems/marketing/MKT-002-campaigns-and-reminders.md) | Campaigns and reminders check consent at every send | marketing | locked |
| [MKT-003](systems/marketing/MKT-003-email-provider.md) | Email goes through the mailer; marketing has its own sender | marketing | locked |
| [MKT-004](systems/marketing/MKT-004-ab-tests.md) | A/B tests assign by hash and recommend a winner only on significance | marketing | locked |
| [MKT-005](systems/marketing/MKT-005-first-party-analytics.md) | Visitor statistics are first-party and consent-gated | marketing | locked |
| [MKT-006](systems/marketing/MKT-006-one-tracker-pixels.md) | Ad pixels go through one tracker, set in the admin, after consent | marketing | locked |
| [OPS-001](systems/ops/OPS-001-supervised-processes.md) | Every process is supervised behind one TLS proxy | ops | locked |
| [OPS-002](systems/ops/OPS-002-ping-and-health.md) | A cheap ping and a real health check | ops | locked |
| [OPS-003](systems/ops/OPS-003-backup-command.md) | The app ships a backup command; the operator owns the rest | ops | locked |
| [OPS-004](systems/ops/OPS-004-configurable-logs.md) | Logs go to stderr or daily files, chosen by config | ops | locked |
| [SEC-001](systems/security/SEC-001-standing-security-rules.md) | Standing security rules | security | locked |
| [SUP-001](systems/support/SUP-001-support-tickets.md) | Post-sale support is its own module | support | locked |
| [TST-001](systems/testing/TST-001-playwright-end-to-end.md) | Playwright runs the end-to-end tests | testing | locked |
| [AUTH-001](systems/php/laravel/AUTH-001-sanctum-spa-cookie.md) | Sanctum SPA cookie, not API tokens | php/laravel | superseded by LRV-008 |
| [LRV-001](systems/php/laravel/LRV-001-layer-scoped-slices.md) | Slicing is scoped to the layer | php/laravel | locked |
| [LRV-002](systems/php/laravel/LRV-002-route-leaves.md) | Route leaves per module; middleware only in the index | php/laravel | locked |
| [LRV-003](systems/php/laravel/LRV-003-nested-model-names.md) | Aggregate children are nested under their owner | php/laravel | locked |
| [LRV-004](systems/php/laravel/LRV-004-installer-migration-names.md) | Framework migrations keep their installer filenames | php/laravel | locked |
| [LRV-005](systems/php/laravel/LRV-005-laravel-roles.md) | Form Requests validate, Policies authorize, Resources serialize | php/laravel | locked |
| [LRV-006](systems/php/laravel/LRV-006-one-admin-authority.md) | One authority says who is an admin | php/laravel | locked |
| [LRV-007](systems/php/laravel/LRV-007-token-table-kept.md) | The personal access token table is kept for future clients | php/laravel | locked |
| [LRV-008](systems/php/laravel/LRV-008-sanctum-spa-cookie.md) | Sanctum SPA cookie, not API tokens | php/laravel | locked |
| [STK-003](systems/php/laravel/STK-003-api-and-web-apps.md) | Two applications: Laravel api/, Nuxt web/ | php/laravel | retired |
| [PHP-001](systems/php/PHP-001-fully-qualified-traits.md) | A trait is used by its fully qualified name | php | locked |
| [PHP-002](systems/php/PHP-002-fully-qualified-class-lists.md) | Classes listed as data are written fully qualified | php | locked |
| [PHP-003](systems/php/PHP-003-vendor-patches-with-tests.md) | A vendor patch ships with its tests | php | locked |
| [PHP-004](systems/php/PHP-004-named-arguments.md) | Arguments are always passed by name | php | locked |
| [PST-001](systems/php/pest/PST-001-pest-lowercase-layout.md) | Pest tests in tests/feature and tests/unit, named *.test.php | php/pest | locked |
| [NXT-001](systems/ts/nuxt/NXT-001-ssr.md) | Nuxt renders on the server (SSR) | ts/nuxt | locked |
| [NXT-002](systems/ts/nuxt/NXT-002-spa.md) | Nuxt renders in the browser only (SPA) | ts/nuxt | locked |
| [RST-001](systems/rust/RST-001-crate-per-slice.md) | A workspace with one crate per feature slice | rust | locked |
| [RST-002](systems/rust/RST-002-kebab-case-crates.md) | Crate packages and folders are kebab-case | rust | locked |
| [RST-003](systems/rust/RST-003-no-mod-rs.md) | A module is `name.rs` beside `name/`, never `mod.rs` | rust | locked |
| [RST-004](systems/rust/RST-004-pinned-toolchain.md) | The toolchain is pinned in `rust-toolchain.toml` | rust | locked |
| [RST-005](systems/rust/RST-005-strict-lints.md) | Strict workspace lints, warnings fail | rust | locked |
| [RST-006](systems/rust/RST-006-naming.md) | Names are one English word, verbs for actions | rust | locked |
| [RST-007](systems/rust/RST-007-validated-newtypes.md) | Domain values are validated newtypes | rust | locked |
| [RST-008](systems/rust/RST-008-no-global-state.md) | No global state, minimal `pub`, traits only when shared | rust | locked |
| [RST-009](systems/rust/RST-009-locked-dependencies.md) | `Cargo.lock` is committed and `cargo deny` runs | rust | locked |
| [RST-010](systems/rust/RST-010-generated-code-crate.md) | Generated code lives in its own crate | rust | locked |
| [RST-011](systems/rust/RST-011-test-tooling.md) | Tests run with nextest, properties with proptest | rust | locked |
| [RST-012](systems/rust/RST-012-build-settings.md) | Builds stay fast through the slice loop and two profile settings | rust | locked |
| [AXM-001](systems/rust/axum/AXM-001-axum-http.md) | axum serves HTTP, with thin routes | rust/axum | locked |
| [SQX-001](systems/rust/sqlx/SQX-001-checked-sql.md) | SQL is written raw and checked at compile time | rust/sqlx | locked |
| [SQX-002](systems/rust/sqlx/SQX-002-sqlx-test.md) | Database tests use `#[sqlx::test]` | rust/sqlx | locked |
| [SQY-001](systems/rust/sea-query/SQY-001-schema-writes-sql.md) | The schema is written in Rust and emitted as committed SQL | rust/sea-query | locked |
