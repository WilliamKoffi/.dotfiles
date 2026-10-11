# Core rubric — every web project

Rate each section `/10`, or write `N/A — <reason>`. The profile file adds sections after these.

## 1. First impression
- Does the first screen say what this is and who it is for?
- Does it look finished and trustworthy, or like a prototype?
- Is the visual hierarchy clear? Is there noise, placeholder or demo content?

## 2. Critical journeys
For each journey named in step 1 of SKILL.md:
- Can a real user complete it end to end, at 1440 and 375 px?
- What happens on error: offline, refused request, invalid input, double click, slow network?
- Is the result persisted and visible afterwards (reload, another device, another user)?

## 3. Navigation & information architecture
Menu clarity, current-page indication, mobile navigation, breadcrumbs, search, back button,
deep links, empty states, 404 page.

## 4. Visual design
Spacing, alignment, consistency, cards, buttons, hover and focus states, loading skeletons,
transitions, image quality, dark mode if offered.

## 5. Typography & color
Font choice and loading, sizes, line height, line length, hierarchy; palette consistency,
accent and CTA colors, contrast.

## 6. Content & language
Grammar, tone, clarity, untranslated strings, mixed languages, jargon, raw values shown to
users (ISO dates, ids, English error keys), number and currency formatting.

## 7. Accessibility (WCAG 2.2 AA)
Contrast, keyboard navigation, focus visible and not obscured, ARIA, semantic HTML, alt
text, form labels, error messages, touch targets (24×24 minimum), reduced motion,
screen-reader names of icons and controls.

## 8. Mobile experience
Layout at 375 px, no horizontal scroll, touch targets, forms and keyboards, sticky elements,
performance on a mid-range phone.

## 9. Performance
LCP, CLS, INP risks; bundle size, unused JS and CSS, images, lazy loading, fonts, caching
headers, compression, API latency of the critical journeys.

## 10. Security
HTTPS, authentication and sessions, password storage, brute-force and rate limits,
authorization on every route (not only in the UI), tenant or user isolation, server-side
validation, file uploads, secrets in the repo or bundle, security headers, CORS, dependency audit.

## 11. Data, money & integrity
Where the project stores data people rely on: transactions, idempotency of retried writes,
totals that reconcile, audit trail, what a delete or cancel does to linked records, backups
and a tested restore.

## 12. Operations & deployment
Reproducible build, environment variables documented, migrations and seed data applied on
deploy, health check, logs and error tracking, persistent storage for uploads, rollback
path, monitoring.

## 13. Privacy & compliance
Privacy policy, terms, legal notice, cookie consent and trackers, data retention, data
export and deletion, the laws of the market served (GDPR, CCPA, local data-protection law).

## 14. Code quality
Structure, naming, folder organization, tests and what they cover, type safety, dead code,
duplicated logic, lint and build green, known findings or TODOs left open.

## 15. Missing features
What a user of this kind of product expects on day one and does not find.
