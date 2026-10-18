# Variant pages for a unit

A **unit** is what gets one page: a whole page (home, listing, product, cart,
checkout, account) or a section shared across pages (nav bar, sidebar, footer, mobile
tab bar, search, drawers, cards).

## Before building

- Read the unit's current code (component, template, route) and write down its
  contract: what it shows, which data it reads, which links and actions it has, and
  which events or DOM hooks other code relies on. Keep that list at the top of the
  page as an HTML comment.
- If a production or dev URL exists, open it and note what works today. Don't lose
  that in a variant.

## Three variants that differ

Vary the **idea**, not the decoration. Useful ways to make them differ:

- **Layout model**: column vs. top bar vs. overlay; grid vs. list vs. editorial
  stack; one page vs. steps vs. accordion.
- **Hierarchy**: what the eye meets first (image, price, story, action).
- **Interaction**: hover vs. tap reveal, sticky vs. hide-on-scroll, drawer vs.
  bottom sheet.

Give each variant a short evocative name (`A « Colonne »`, `B « Pilule flottante »`)
and a one-line pitch in the switcher bar. If the user likes one but not everything
in it, make sub-variants of it (`?v=c1…c4`) and change one thing per sub-variant, so
the comparison stays readable.

## Page mechanics (from `_template.html`)

- The switcher bar is fixed at the top and clearly not part of the design. It holds
  the unit name, the variant links, the state toggles (`&empty`, `&loading`,
  `&error`, `&guest`), and, while the theme is still open, the theme links
  (`?theme=`).
- `render[V]()` per variant draws into `[data-root]`. Shared data loading happens
  once, before rendering.
- Data: prefer live data through the server proxy (`/api/...`). Fall back to a JSON
  fixture next to the page (`<unit>.json`) built from real records. Simulate writes
  (cart, forms) in the page, following the API's rules (validation, limits).
- Stand-ins: when a unit needs its neighbours (a page needs the nav bar), use the
  decided variant of the neighbour if there is one, otherwise a neutral stand-in, and
  mark it as such in a comment.

## Check before showing

- At 375 px and at 1440 px: no horizontal scroll, the tap targets are at least 44 px,
  and long names wrap or truncate cleanly.
- Tab through the page: the focus ring is visible, and the order makes sense.
- Under `prefers-reduced-motion`, motion is off or reduced to fades.
- No hex or font outside `theme.js` (grep the page for `#[0-9a-fA-F]{3,6}` and for
  `font-family`).
