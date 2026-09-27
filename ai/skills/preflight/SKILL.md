---
name: preflight
description: Pre-launch production-readiness audit of a website or web app against 26 items — GDPR/CCPA legal pages, cookie consent, tracker inventory, business identity, WCAG 2.1 AA accessibility, SEO metadata, secrets exposure, form validation, spam protection and security headers — each reported PASS/PARTIAL/FAIL/MISSING with file:line evidence, then fixed with production-ready code on approval. Use whenever the user is about to launch, ship, go live, or deploy to production; asks whether a site is "production ready", "launch ready", "compliant" or "safe to ship"; or asks for a pre-launch checklist, GDPR/CCPA review, cookie-consent review, accessibility audit, legal-pages review or secrets sweep — even when they name only one of those areas, since these failures cluster.
argument-hint: "[--fix [items]] [path]"
---

# preflight

A launch audit is worth something only if it can say **no**. The failure mode of
this work is not missing a bug — it is a confident green report over an untested
claim. So the discipline here is: every verdict carries a `file:line`, absence of
evidence is never a pass, and a single legal failure blocks the launch regardless
of how good the other 25 items look.

The second failure mode is subtler and worse. Writing a privacy policy means
naming a data controller; writing an imprint means stating a registered address.
A model that guesses those produces a document that *looks* authoritative and is
legally void — it misidentifies who is liable. That is why §0 is blocking.

## Invocation

```
/preflight                  audit + report, writes nothing
/preflight --fix            audit + report, then apply every fix
/preflight --fix 5,12,19    apply only those item numbers
/preflight ./apps/web       audit a subdirectory
```

Default is report-only. Fixes land after the user has seen the report, because
the right fix for "no refund policy" depends on facts only they have.

## 0. Intake — blocking, before any audit work

Do not scan, do not read files, do not produce partial findings first. Ask, then
wait. Items 1–4, 8 and 10 are unanswerable without this, and a half-audit invites
the user to act on the half that looked fine.

Ask for, in one grouped exchange:

- **Target markets** — the countries or regions where users actually are. This
  picks the regime: EU/EEA and UK → GDPR + ePrivacy + (EU) the Accessibility Act;
  California → CCPA/CPRA; Canada → PIPEDA; Brazil → LGPD. Selling into the EU
  also triggers consumer-law duties the refund policy must reflect.
- **Legal entity** — registered name, legal form, registered address, company
  registration number, VAT number where it applies. This is the controller
  identity that every legal page must name.
- **Contact** — support email, and a phone number or equivalent direct channel
  (several jurisdictions require a non-form contact route). DPO details if one is
  appointed.
- **Money** — is anything sold, subscribed to, or refundable? Prices tax-inclusive
  or not? This decides whether item 3 applies at all and what deadlines it states.
- **Processors** — who personal data is sent to (hosting, analytics, email, AI
  APIs, payments). The privacy policy must list these, and the tracker audit in
  item 6 checks the list against reality.

If the user cannot supply something — no VAT number yet, address not registered —
record it as an **open blocker** in the report. Do not invent it and do not paper
over it with a placeholder. "No placeholders" and "no fabricated legal facts" are
the same rule seen from two sides: the document ships complete or it does not ship.

Legal text produced here is a well-researched draft, not legal advice. Say so once,
in the report, without belabouring it.

## 1. Scope the surface

Run the bundled scanner first — it is read-only and mutates nothing:

```bash
bash ~/.claude/skills/preflight/scripts/scan.sh <path>          # all sections
bash ~/.claude/skills/preflight/scripts/scan.sh <path> secrets  # one section
```

It is ripgrep-backed, so `.gitignore` is honoured: build output and vendored code
are skipped, untracked source is not. It reports where to look; it does not decide
anything. Read the files it points at before writing a verdict about them.

Then load the reference for the detected stack — these hold the concrete file
paths and idioms, so the checklist below can stay stack-neutral:

| Stack signal | Read |
|---|---|
| `next.config.*`, `app/` or `src/app/` | `references/nextjs.md` |
| `artisan`, `composer.json` | `references/laravel.md` |
| anything else, or plain HTML/Astro/Vite/SPA | `references/generic.md` |

Two more, by topic rather than stack:

- `references/consent.md` — item 5 is the hardest to get right; read before touching it.
- `references/legal-text.md` — clause requirements for items 1–4, per regime.

Enumerate every public route before auditing items 17–19, 23. An audit of the
pages you happened to open is not an audit.

## 2. Evidence discipline

Four verdicts, and the difference between the last two matters:

- **✅ PASS** — you opened the file and the requirement is met. Cite `path:line`.
- **⚠️ PARTIAL** — present but insufficient. Say precisely what is short.
- **❌ FAIL** — present and wrong, or actively harmful. Cite the offending line.
- **⬜ MISSING** — searched for, not found. Name what you searched for.

A scanner miss is `⬜ MISSING`, never `✅ PASS`. If you could not check something —
no credentials, no deployed URL, needs a real browser — mark it **UNVERIFIED** and
say what would settle it. An honest unknown is useful; a guessed pass is not.

## 3. The 26 items

### A. Legal & compliance

1. **Privacy policy** — exists, reachable from the footer of every page, and
   contains the clauses in `references/legal-text.md` for each regime from §0:
   controller identity, lawful bases per purpose, categories collected, recipients
   (must match item 6), retention periods, transfer mechanism, and the rights list
   with a working exercise route.
2. **Terms & conditions** — governing law and forum named, and consistent with the
   §0 entity. Check liability limits are not void in the target jurisdiction.
3. **Refund policy** — only if §0 says money changes hands. Must state the window,
   what qualifies, how to request, and the refund timeline. In the EU, the 14-day
   statutory withdrawal right and any valid waiver for digital goods.
4. **Cookies policy** — names each cookie individually: name, purpose, duration,
   first or third party. A generic "we use cookies" page is `⚠️ PARTIAL`.
5. **Cookie consent banner** — see `references/consent.md`. The test is behavioural,
   not cosmetic: with a clean profile, nothing non-essential may fire before an
   opt-in. Reject must be one click and as prominent as accept. Pre-ticked boxes
   and confirm-shaming are `❌ FAIL`.
6. **Tracking audit** — enumerate every tracker, tag, pixel, embed and font CDN.
   Cross-check three ways: the list matches the cookies policy (4), matches the
   privacy policy's recipients (1), and nothing fires pre-consent (5). Third-party
   iframes and webfonts count — they set cookies and leak IPs.
7. **Form consent** — opt-in checkboxes unchecked by default, marketing consent
   separate from T&C acceptance, granular per purpose. Bundling them is `❌ FAIL`;
   consent must be separable to be freely given.
8. **Local law** — for each §0 market, the obligations the others miss: EU imprint
   duties, UK company-details rules, EU Accessibility Act for consumer services,
   CPRA's "Do Not Sell or Share" link where the definition bites.
9. **Unsupported claims** — every statistic, rating, "trusted by N" and guarantee
   traced to a source. Untraceable ones get cut or qualified, not softened. This is
   advertising law, and the numbers in a fresh template are usually invented.

### B. Trust & transparency

10. **Business details** — the §0 entity name, address, registration number and
    contact reachable from the footer and repeated in the legal pages. An email in
    a contact form only is not reachable.
11. **Data minimisation** — list every field of every form and justify it against
    a stated purpose. Unjustifiable fields get deleted, not made optional; the
    lawful basis is per-field. Phone on a newsletter form is the classic `❌ FAIL`.

### C. Accessibility & UX — WCAG 2.1 AA

12. **Semantics & ARIA** — landmarks, one `h1` with no skipped levels, inputs
    programmatically labelled, visible focus, dialogs that trap focus and restore
    it on close, live regions for async results. Prefer a native element over ARIA
    on a `div`: the first is correct by construction.
13. **Alt text** — every image conveys its *function*, not its contents. A logo
    linking home is alt "Home", not "company logo". Decorative images take `alt=""`
    deliberately. CSS background images that carry meaning need a text alternative.
14. **Button labels** — the label must make sense read alone, out of context, since
    that is how a screen-reader element list presents it. "Click here" and a bare
    "Submit" are `❌ FAIL`; icon-only controls need an accessible name.
15. **Keyboard** — full keyboard traversal, logical tab order, no traps, Enter
    submits forms, Escape closes overlays, focus visible at every stop. Walk it,
    do not infer it.

### D. Technical & SEO

16. **Secrets** — no key, token or credential in client-shipped code. Scan the
    build output, not just source: public-prefixed env vars are compiled in. A
    secret found here is also a **rotation** task, not only a code change — treat
    it as exposed from its first commit.
17. **Meta** — unique title and description per route, titles ~50–60 chars,
    descriptions ~150–160. Duplicates across routes are `⚠️ PARTIAL`.
18. **Social preview** — OG and Twitter tags with a real 1200×630 image, absolute
    URL. Verify the file exists at the referenced path.
19. **Sitemap & robots** — both present and valid, sitemap listing real canonical
    URLs. A staging `Disallow: /` or a stray `noindex` reaching production is a
    launch blocker — check it explicitly.
20. **Speed** — LCP under 2.5s on mobile. Look at render-blocking resources, font
    loading strategy, unoptimised images, and what ships in the initial bundle.
21. **Mobile** — no horizontal scroll at 320px, touch targets ≥44px, text readable
    unzoomed, viewport meta present and not scale-locked.
22. **404** — on-brand, genuinely helpful links, and returning a real HTTP 404. A
    soft-404 (200 with error content) is `❌ FAIL` — it poisons indexing.
23. **Links** — crawl internal and external. Fix internal breaks; 301 moved routes;
    replace or drop dead external links. Check footer legal links resolve.
24. **Form validation** — server-side validation on every endpoint, client-side as
    convenience only. Inline errors tied to inputs via `aria-describedby`. Client
    validation without a server counterpart is `❌ FAIL` whatever the UI looks like.
25. **Spam protection** — honeypot plus rate limiting plus a captcha, all enforced
    server-side on every public form. Client-only checks are decorative.
26. **Security headers & HTTPS** — HSTS, a CSP that is actually restrictive,
    `X-Content-Type-Options: nosniff`, `Referrer-Policy`, frame protection, HTTP→HTTPS
    redirect, no mixed content. A CSP with `unsafe-inline` on scripts is `⚠️ PARTIAL` —
    say what it would take to remove.

## 4. Report format

One section per item, in checklist order, nothing omitted — an item skipped in
silence reads as a pass:

```
## [7] Form consent — ❌ FAIL
**Evidence** — src/components/ContactForm.tsx:42 — single checkbox covers both
  "I accept the Terms" and "Send me product updates"; `defaultChecked` on :44.
**Risk** — Bundled consent is not freely given (GDPR Art. 7(2)), and pre-ticked
  boxes were rejected in Planet49 (C-673/17). Marketing sent on this basis is unlawful.
**Fix** — <full code, or "applied — see diff" in --fix mode>
```

Then:

- **Verdict** — LAUNCH READY or NOT READY, by the rule in §6.
- **Blockers** — ordered by legal exposure, then user harm, then everything else.
- **Open questions** — the §0 gaps and anything marked UNVERIFIED.

Lead the reply with the verdict and the blocker count. A launch decision is the
one thing the user needs in the first line.

## 5. Fix protocol

In report-only mode, give the complete code inline — the user may apply it by hand.

In `--fix` mode:

- Work the blockers first, in the §4 order, so an interrupted run still leaves the
  user better off legally than it found them.
- One coherent change per item. Do not fold an accessibility fix into a consent
  refactor; the user needs to review and revert these independently.
- Match the codebase — its router, component idioms, styling system and i18n. A
  correct fix in a foreign style will be rewritten and lost.
- Never weaken a control to make something pass: not a loosened CSP, not a removed
  validation, not `outline: none` to tidy a focus ring, not an `aria-label` papering
  over a wrong element. If an item cannot be fixed without that trade, leave it
  failing and explain the trade in the report.
- Re-verify each fix against the same evidence rule that failed it, and say plainly
  which items you fixed, which you could not, and why.

## 6. Verdict

NOT READY if any of these is true — state which rule fired:

- any `❌ FAIL` or `⬜ MISSING` in A (items 1–9) or item 10
- a secret exposed client-side (16)
- a public form with no server-side validation (24) or no spam protection (25)
- a production `noindex` / `Disallow: /` (19), or a soft-404 (22)
- any WCAG 2.1 AA failure that blocks a task outright — unlabelled input on a
  required field, keyboard trap, unreachable control (12, 15)

Otherwise LAUNCH READY, with remaining `⚠️ PARTIAL` items listed as post-launch work.

Do not soften a verdict because the list is long or the user is close to shipping.
They asked for the audit so that someone would say the uncomfortable thing.
