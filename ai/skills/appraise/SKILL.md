---
name: appraise
description: Runs a multi-persona, evidence-based audit of any web project (marketing site, SaaS or web app, e-commerce, back-office or point of sale, law firm or luxury services) across product, UX, visual design, accessibility (WCAG 2.2), performance, SEO, security, operations and code, each section rated /10, ending in a go/no-go launch verdict, a prioritized roadmap and an executive summary. Use when asked to audit, appraise, critique, review, score, or check whether a website or web app is ready to launch or ready for production.
---

# appraise — audit a web project before launch

A panel of experts audits the project as it is today and says whether it can launch.
The panel and the rubric adapt to what the project **is**; the method never changes.

## 1. Identify the project (before any judgement)

Read, in this order, and stop when the answers are clear:

1. The entry docs: `README*`, `AGENTS.md`, `CLAUDE.md`, `docs/product/`, `PRD*`.
2. The stack: `package.json`, `Cargo.toml`, `composer.json`, framework config, `Dockerfile`, deploy files.
3. The routes: what a visitor sees without logging in, and what sits behind a login.

Then state, in four lines, before auditing:

- **Profile** — the closest file in `references/profiles/` (two at most):
  `marketing-site`, `saas-app`, `ecommerce`, `back-office-pos`, `law-firm-luxury`.
- **Audience** — who uses it, on what device, with what at stake (money, legal, health, data).
- **Launch target** — public site, private app, internal tool; where it deploys.
- **Critical journeys** — the 3 to 6 paths that must work on day one (sign in, ring a sale,
  record a payment; or land, read, contact).

If the user named a focus ("can users pay?", "is it SEO-ready?"), it becomes a critical
journey and is answered first, whatever the profile.

## 2. Assemble the panel

Always: Product Manager, UX/UI Designer, Frontend Architect, Accessibility Expert (WCAG 2.2),
Security & Operations Engineer, QA Lead.

Then add the personas the profile file lists. Do not seat a persona whose subject the
project does not have.

## 3. Gather evidence

Every finding rests on evidence. Use what the environment allows, best first:

- **Run it.** The project's own lint, test and build commands; record the counts printed.
- **Drive it.** Open the app in a browser at 1440 px and 375 px, walk every critical journey
  as a person would, read the console and the network. Screenshots in a scratch folder.
- **Read it.** `file:line` for code, config and deploy facts.
- **Read its own records.** Open issues, findings, task boards, TODOs: they are known gaps.

Label each finding **observed** (seen running, or a command's output) or **read** (from code
or docs only). A journey not walked is "not verified", never assumed to work.

## 4. Audit

Work through `references/rubric.md` (the core sections, every project), then the extra
sections of the profile file. A section that does not apply is written `N/A — <reason>` and
left out of the averages; it is never scored to fill the grid.

For every observation:

- **What** — the fact, with its evidence.
- **Why** it is a problem.
- **Impact** — on trust, usability, accessibility, SEO, conversion, money, data, or operations.
- **Fix** — a concrete recommendation, with an implementation example when possible.

Delegate rather than duplicate: if a `preflight` skill exists, use it for legal pages,
cookie consent, trackers and security headers, and cite its results.

## 5. Output

1. **Launch verdict** — `GO`, `GO with conditions`, or `NO-GO` in one line, then the
   blockers: each failing critical journey, money or data-loss risk, security hole, or
   legal requirement, with its evidence.
2. **Critical journeys** — a table: journey · status (works / broken / not verified) · evidence.
3. **Improvement roadmap** — Critical (blocks launch), High, Medium, Low.
4. **Scoring** — `/10` per section audited, N/A sections listed apart, an overall score.
5. **Executive summary** — the profile file's questions, plus always:
   - Would you launch this today, and for whom?
   - The improvements that make the biggest difference (20 at most; fewer if fewer matter).
   - What to fix first, and why that order.

A 10 means nothing worth fixing was found, not that the section looks fine.
Write the report in the user's language.
