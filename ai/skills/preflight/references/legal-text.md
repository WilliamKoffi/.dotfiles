# Legal page clause requirements — items 1–4, 8

Clause checklists, not boilerplate. Copying a generic policy is how sites end up
promising things they do not do; drafting against these lists and the §0 intake
facts is how you get a document that describes the actual system.

Everything here is a well-researched engineering checklist. Final legal pages for
a real business should be reviewed by a qualified lawyer in the target market —
state that once in the report, then get on with it.

- [Privacy policy (item 1)](#privacy-policy-item-1)
- [Terms & conditions (item 2)](#terms--conditions-item-2)
- [Refund policy (item 3)](#refund-policy-item-3)
- [Cookies policy (item 4)](#cookies-policy-item-4)
- [Regime specifics (item 8)](#regime-specifics-item-8)

## Privacy policy (item 1)

GDPR Arts. 13–14 make this an itemised disclosure, not an essay. Required:

- **Controller identity** — the registered legal name from §0, registered address,
  and a contact route. Trading name alone fails; liability attaches to the entity.
- **DPO or representative** — contact details if one is appointed or required.
- **Purposes with a lawful basis for each** — one basis per purpose, named. This is
  the clause most often wrong: "we process your data to improve our service" states
  no basis. Where the basis is legitimate interests, name the interest.
- **Categories of personal data**, including anything inferred or derived.
- **Recipients or categories of recipient** — the §0 processor list. Must match the
  trackers found in item 6; a mismatch means one of the two documents is false.
- **Third-country transfers** — which countries, and the mechanism (adequacy
  decision, SCCs). A US-hosted analytics tool is a transfer.
- **Retention period per category**, or the criteria used to determine it.
  "As long as necessary" alone is not a criterion.
- **Rights** — access, rectification, erasure, restriction, portability, objection,
  and withdrawal of consent, each with a route that actually works. Plus the right
  to lodge a complaint with a named supervisory authority.
- **Automated decision-making / profiling** — logic and consequences, if any.
- **Whether provision is statutory or contractual** and what happens if refused.
- **Children** — age threshold and how it is enforced, if the service reaches minors.
- **Last-updated date** and how changes are communicated.

CCPA/CPRA adds, for California residents:

- Categories collected, sold, or shared **in the preceding 12 months**, with
  categories of third party per bucket.
- The business or commercial purpose for each.
- Rights to know, delete, correct, and opt out of sale/sharing, plus the right to
  limit use of sensitive personal information.
- A **"Do Not Sell or Share My Personal Information"** link where the (broad)
  definition of sharing applies — cross-context behavioural advertising counts.
- Non-discrimination for exercising rights, and how authorised agents may act.
- Whether Global Privacy Control signals are honoured. If the site claims to honour
  GPC, verify it does — an unhonoured claim is its own violation.

## Terms & conditions (item 2)

- Entity identification consistent with the privacy policy and the footer.
- Service description, eligibility, and account duties.
- Acceptable use, and the grounds and notice period for suspension or termination.
- IP ownership — including who owns user-generated content and what licence the
  operator takes over it. Overbroad licences are a common consumer-law problem.
- Payment terms, renewal and cancellation mechanics, cross-referencing item 3.
- Warranties and liability limits. Check these against local consumer law before
  shipping them: in the EU and UK, blanket exclusions of liability toward consumers
  are unenforceable, and an unenforceable clause can taint the surrounding terms.
- Governing law and forum. For consumers in the EU/UK, a foreign forum clause does
  not displace their home-court protections — say so rather than implying otherwise.
- Amendment process with notice, and a dated version.

## Refund policy (item 3)

Only applies if §0 reports money changing hands. Must state:

- The refund window in days, and when the clock starts.
- What qualifies and what does not, in plain terms.
- How to request it — a route that works, not an unmonitored address.
- Processing time and the method refunds are returned by.
- Who pays return costs, where physical goods exist.

**EU/UK digital goods**: consumers have a 14-day right of withdrawal. It can be
waived for digital content delivered immediately, but only with the consumer's
prior express consent *and* acknowledgement that the right is lost — both captured
at purchase. If the checkout does not capture them, the waiver is invalid and the
policy claiming it is misleading. Check the checkout, not just the policy text.

Subscriptions additionally need renewal terms, cancellation effect (immediate or
end-of-period), and any pro-rata rule stated up front.

## Cookies policy (item 4)

A table, one row per cookie — this is what makes it auditable:

| Name | Provider | Purpose | Duration | Category | First/third party |

Categories should match the consent banner's toggles exactly, or users cannot
exercise the choice the banner offers. Include `localStorage` and `sessionStorage`
entries: ePrivacy covers storage of and access to information on a device, not the
cookie mechanism specifically.

Essential cookies are only those without which a user-requested service cannot
work — a session token, a CSRF token, a load-balancer affinity cookie. Analytics
is not essential, however genuinely useful it is. Miscategorising analytics as
essential is the single most common way a consent implementation fails.

## Regime specifics (item 8)

- **EU imprint duties** — several member states require a named representative,
  registration number and direct contact. Germany's Impressum rules are strictest
  and apply to commercial sites reaching German users.
- **EU Accessibility Act** — applies to consumer-facing e-commerce and digital
  services; it turns the item 12–15 WCAG work from best practice into a duty.
- **France** — `mentions légales` with publisher, host name and address; CGV for sales.
- **UK** — Companies Act requires company name, registered number, registered office
  and place of registration on the website.
- **Germany** — Impressum plus, for sales, a clearly labelled order button.
- **California (CPRA)** — the opt-out link, GPC handling, and sensitive-data limits.
- **Canada (PIPEDA)** — meaningful consent, purpose limitation, and a named privacy
  officer with contact details.
- **Brazil (LGPD)** — legal bases mirroring GDPR, plus a data protection officer.

For any market in §0 not listed here, research it rather than assuming it resembles
GDPR, and record what you checked so the next audit can build on it.
