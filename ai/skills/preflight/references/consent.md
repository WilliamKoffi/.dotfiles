# Cookie consent — item 5

Most consent banners fail for the same reason: the banner is treated as a UI
component, so it renders while the scripts it is supposed to gate have already
run. Consent is a **loading gate**, not an overlay. If the tag fires and the
banner appears on top of it, there is no implementation at all — only a notice.

## What a correct implementation does

1. **Nothing non-essential loads on first paint.** No GA, no pixel, no Hotjar,
   no third-party font, no embedded map or video iframe. Essential only.
2. **The banner offers a real choice.** Accept, Reject, and granular per-category
   toggles. Reject is one click, from the first screen, styled with the same
   prominence as Accept. Burying Reject behind "Manage preferences" is a dark
   pattern and fails Art. 7(3) — withdrawal must be as easy as giving.
3. **Toggles start off.** Every non-essential category defaults to off. Pre-ticked
   boxes are settled law (Planet49, C-673/17): they are not consent.
4. **The choice is recorded** with categories, timestamp and policy version, so it
   can be evidenced and re-prompted when the policy changes.
5. **Scripts load on the consent event**, not on reload. A banner requiring a page
   refresh to take effect will silently lose consents.
6. **Withdrawal is reachable** from every page — a footer link reopening the
   preferences, for the life of the site.
7. **Rejection persists.** A banner that reappears every page load until accepted
   is coercive, and reads as a dark pattern regardless of intent.

## Categories

Keep them few and honest — the categories in the banner, the cookies policy table
and the code must be the same set:

- `necessary` — always on, no toggle. Session, CSRF, load balancing, consent record.
- `analytics` — usage measurement. Off by default, always.
- `marketing` — advertising, retargeting, conversion pixels.
- `preferences` — non-essential personalisation such as a remembered theme.

## The essential-cookie trap

"Essential" means the *user-requested service* cannot function without it — not
that the business considers it important. Analytics is never essential. Nor is a
CDN-hosted webfont, an embedded YouTube player, or a support-chat widget that
loads before anyone opens it. Each of those is a third-party request carrying the
user's IP and typically setting storage, so each needs gating.

Self-host fonts rather than gating them. It removes a consent category, removes a
third-party dependency, and is faster — which also helps item 20.

## Google Consent Mode v2

If GA or Google Ads is present, Consent Mode must be initialised with everything
**denied** before the tag loads, then updated on choice. The default block runs
first, synchronously, ahead of the gtag snippet:

```js
window.dataLayer = window.dataLayer || [];
function gtag() { dataLayer.push(arguments); }

gtag('consent', 'default', {
  ad_storage: 'denied',
  ad_user_data: 'denied',
  ad_personalization: 'denied',
  analytics_storage: 'denied',
  functionality_storage: 'denied',
  personalization_storage: 'denied',
  security_storage: 'granted',
  wait_for_update: 500,
});
```

On the user's choice:

```js
gtag('consent', 'update', {
  analytics_storage: choice.analytics ? 'granted' : 'denied',
  ad_storage: choice.marketing ? 'granted' : 'denied',
  ad_user_data: choice.marketing ? 'granted' : 'denied',
  ad_personalization: choice.marketing ? 'granted' : 'denied',
});
```

Consent Mode alone is not compliance: with storage denied, Google still receives
cookieless pings. For EU visitors the tag itself should not load until consent,
with Consent Mode as the second layer rather than the only one.

## Storing the record

Store the decision in a first-party cookie or `localStorage` — that storage is
itself strictly necessary, so it needs no consent:

```json
{ "v": 1, "ts": "2026-09-20T10:00:00Z",
  "categories": { "analytics": false, "marketing": false, "preferences": true } }
```

Version it. When the cookie list materially changes, bump the version and re-prompt;
consent obtained for a different set of processors does not carry over.

## Verifying it — behaviourally

A code read cannot settle this item. With a clean profile and devtools open:

1. Load the site. Record every network request and every cookie and storage entry
   written **before** interacting with the banner. Non-essential entries here are
   an immediate `❌ FAIL`, and the request list is the evidence.
2. Click **Reject all**. Reload. Confirm no new non-essential requests, and that
   the banner does not return demanding another answer.
3. Accept analytics only. Confirm analytics fires and marketing does not — this is
   where per-category gating usually turns out to be all-or-nothing in disguise.
4. Withdraw via the footer link. Confirm the scripts stop on the next load and the
   stored record actually changed.

Record the request lists in the report. "Reviewed the banner component" is not
evidence for this item; the network tab is.

## Accessibility of the banner itself

It is a dialog, so items 12 and 15 apply to it: focus moves into it on appear,
Escape does not dismiss it as silent acceptance, the buttons are real `<button>`
elements, and it does not trap keyboard users who decline. A consent banner that
is itself inaccessible fails twice.
