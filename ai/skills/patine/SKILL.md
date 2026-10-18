---
name: patine
description: Give a project its visual theme through isolated HTML variant pages kept in a playground. With no theme, brainstorm three distinct directions fitted to the project's concept and render them side by side to pick one; with a theme (words, a palette, a URL, a screenshot, existing tokens), turn it into tokens and redesign the project unit by unit — whole pages or shared sections like the nav bar, sidebar, footer — each as an A / B / C variant page to compare and choose from. Use whenever the user wants a theme, a look and feel, a visual identity, a redesign direction, a palette or type pairing for a project, wants to compare design variants of a page or section, or asks "what style should this site have".
argument-hint: [theme brief | path | url] | next | <unit> | (empty: brainstorm)
---

# patine

Finds or applies a theme for the project in the working tree, and proves it on the
project's own content through standalone HTML pages that offer competing variants.
Everything lives in one playground under `trash/playground/<ctx>/`. No application
code changes. The output is a decided theme and a decided variant per unit, ready to
be built later.

## The playground

Read `~/.claude/skills/playground/SKILL.md` and follow it for the folder: context
naming, the **Tracker** files (`README.md`, `progress.md`, `log.md`, `events.md`),
registration in `trash/playground/README.md`, and the update rules. This skill only
adds the theme files and the variant pages to that folder.

- `ctx` defaults to `<project>_theme` (`lmdl_theme`). If a theme playground already
  exists (it has `theme.js`), **resume it**: read every note, then continue from
  `progress.md`. Never start a second theme playground for the same project.
- On first run copy `assets/theme.js`, `assets/server.ts` and `assets/unit.html` (the
  page template, kept as `_template.html`) into the folder.

Folder layout:

```
trash/playground/<ctx>/
  README.md  progress.md  log.md  events.md   ← playground tracker
  concept.md                                  ← what the project is, step 1
  theme.js                                    ← the tokens, the one source of truth
  server.ts  _template.html
  00_directions.html                          ← brainstorm only
  00_specimen.html                            ← tokens on basic components
  NN_<unit>.html                              ← one per page or section
  screenshots/
```

## Arguments

| `$ARGUMENTS` | Mode |
|---|---|
| empty, no theme playground yet | **Brainstorm** (steps 1, 2a, 3, 4) |
| a theme: words, palette, font names, URL, image path, a tokens/CSS file | **Given theme** (steps 1, 2b, 3, 4) |
| `next` | resume, take the next open unit in `progress.md` (step 5) |
| a unit name (`navbar`, `product page`) | resume, do that unit (step 5) |

## 1. Read the concept → `concept.md`

A theme must fit the project, so understand the project first. Read the README,
`AGENTS.md`/`CLAUDE.md`, `docs/decisions/`, the existing styles (Tailwind config, CSS
variables, the logo and favicon), the real content (seeders, API responses, product
names and photos), the routes, and any older design playground. Write `concept.md`:

- **What and for whom**: the offer, the audience, the market and its locale and
  currency, the price level, the devices people use (phone first?).
- **Tone**: 3–5 adjectives the evidence supports, each with its source.
- **Keep**: what must survive (logo, a brand colour, a font, a contract or behaviour).
- **Constraints**: WCAG 2.2 AA, performance budget, languages, dark mode or not.
- **Units**: the inventory of pages and shared sections (nav bar, sidebar, footer,
  drawers, cards, forms). Read them from the routes and the layout components; don't
  guess.

Show the user a 5-line summary and let them correct it before going on. A wrong
concept wastes every page that follows.

## 2a. Brainstorm: three directions

Read `references/directions.md`. Propose **three directions that differ on real
axes** (e.g. editorial vs. warm craft vs. bold modern), not three tints of one idea.
For each one give a name, a one-line thesis, why it fits (cite `concept.md`), the
tokens, the imagery and texture, the motion, a microcopy sample, and the risk it
carries.

Write all three into `theme.js` as `THEMES = { a, b, c }`. Build
`00_directions.html`: the **same real slice** (header, hero, a product or content
card, a button and a form field, the footer) rendered once, with the theme switched
by `?theme=a|b|c`. Then add a `?compare` view that shows the three side by side at
phone width.

The user picks one, mixes two ("A's palette with C's type"), or asks for
sub-directions (`a1`, `a2`…). Iterate until one theme is chosen, then keep only it in
`THEMES` (`{ main }`). Note the rejected ones in `events.md` with the reason.

## 2b. Given theme

Turn what the user gave into tokens (`references/directions.md` → *Tokens*). From an
image or a URL, sample its colours and identify its fonts, and say which values are
estimates. Fill the gaps it leaves (a muted ink, a line colour, a type scale) from
`concept.md`, and list them as **inferred** so the user can overrule them. Ask only
when the brief contradicts itself or contradicts a **Keep** item.

## 3. Lock the tokens

- Run `bun ~/.claude/skills/patine/scripts/contrast.mjs trash/playground/<ctx>/theme.js`.
  Fix every FAIL before showing anything. A theme that fails AA is not a candidate.
- Build `00_specimen.html`: palette with roles, the type scale, buttons (every state),
  a form field (focus, error), a card, a badge, links, and the radius and shadow
  steps. Use real words from the project, not lorem ipsum.
- Record the decision in `events.md` (dated) and add the roadmap of units to
  `progress.md`. Order: the shared shell first (nav bar, footer, sidebar, mobile bar),
  because it frames every page; then the pages that get the most traffic. The user
  can reorder the list.

## 4. Serve and show

`bun trash/playground/<ctx>/server.ts` serves the folder on port 3333. Set
`API_PROXY=http://localhost:8000/v1` to map `/api/*` to a local API when pages use
live data, and `PUBLIC_DIR=web/public` to serve the app's images. Give the user the
URLs. If browser tools are available, take screenshots at 375 px and 1440 px and save
them in `screenshots/`.

## 5. Unit by unit

Read `references/units.md`. For each unit, copy `_template.html` to `NN_<unit>.html`
and build **three variants (`?v=a|b|c`) that differ in structure or idea**, all
inside the theme:

- Use only the tokens. A hex or font not in `theme.js` means the theme is missing
  something: add the token, don't hard-code it.
- Show real content and the states that matter (empty, loading, error, logged out,
  long names, many items), each behind a switcher toggle.
- Make it work at 375 px and at desktop width, with keyboard focus visible and
  `prefers-reduced-motion` respected.
- Keep the project's behaviour contracts (what links where, which fields, which
  events). A variant changes the design, not what the unit does.

Show the page. The user picks, mixes, or asks for sub-variants (`?v=c1…c4`). Record
the choice in `events.md` (unit, variant, what was changed, date), tick it in
`progress.md`, append to `log.md`, then propose the next unit and stop.

## Rules

- Isolated: pages run from the playground folder with the CDN and `theme.js` only.
  Don't import from the app, and don't edit app code or config.
- `theme.js` is the single source: every page loads it, so changing a token restyles
  every page at once. Say so when you change one.
- Never `git add` the playground (it is under `trash/`, which is gitignored).
- Write the UI copy in the project's language. Write the notes in the language of
  the existing playground notes.

## Report

Each turn ends with: what was built (file names and URLs), what the user should
compare and the one question to answer ("A, B or C?"), and anything inferred or not
verified.
