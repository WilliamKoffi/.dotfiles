# Static sites, Astro, Vite, and client-rendered SPAs

The fallback reference: plain HTML, Astro, SvelteKit, Nuxt, Vite + React/Vue, and
anything hosted on Netlify, Cloudflare Pages, GitHub Pages or a plain web server.

## Secrets (16)

Every bundler inlines its public-prefixed vars at build time. There is no runtime
secret in a client-rendered app — if the browser can reach it, so can anyone.

| Bundler | Public prefix |
|---|---|
| Vite / Astro / SvelteKit | `VITE_`, `PUBLIC_` |
| Nuxt | `NUXT_PUBLIC_` |
| Create React App | `REACT_APP_` |
| Vue CLI | `VUE_APP_` |

Check the built output, since source-level indirection hides the read:

```bash
rg -o 'sk_live_[A-Za-z0-9]+|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{20,}' dist/ -r '$0' | sort -u
```

A pure static site that needs a secret needs a server — a serverless function or a
backend proxy. There is no configuration that makes a client-side secret private,
so do not accept "it is obfuscated" as a mitigation.

## Metadata (17, 18)

A client-rendered SPA that sets tags with JavaScript will render correctly in a
browser and produce **empty previews** on every social crawler, since most do not
execute JS. Check with the raw response, not devtools:

```bash
curl -s https://example.com/some-route | rg -i '<title>|og:|twitter:'
```

If the tags are absent there, item 18 is `❌ FAIL` however good the page looks
in-browser. The fix is prerendering or SSR for public routes — a meta-tag library
alone does not solve it.

Astro and SvelteKit render server-side by default, so their tags are in the HTML;
verify anyway, because a route opted into client-only rendering loses them.

## robots and sitemap (19)

`public/robots.txt` and `public/sitemap.xml` are copied to the output root. Confirm
they are in the *built* output, not only the source tree, and that the sitemap
lists absolute canonical URLs. Check for a `Disallow: /` left over from staging —
the single most common launch-day SEO failure.

Astro has `@astrojs/sitemap`; SvelteKit and Nuxt have equivalents. A generated
sitemap beats a hand-maintained one, which falls behind silently.

## 404 (22)

This is where static hosts differ, and where soft-404s come from:

- **Netlify** — `public/404.html` is served with a real 404.
- **Cloudflare Pages** — same, `404.html` at the output root.
- **GitHub Pages** — `404.html` is served, but **with status 200**. That is a
  soft-404 by construction and cannot be fixed on Pages; note it as a platform
  limitation rather than a code fix.
- **SPA with a catch-all rewrite** — every unknown path returns 200 with the shell.
  Hard-fails item 22. The fix is a server-side rule that returns 404 for unmatched
  routes, or prerendering the real route list.

Always verify with the status line, never the rendered page:

```bash
curl -sI https://example.com/definitely-not-a-real-page | head -1
```

## Headers (26)

Static hosts take headers from a config file rather than application code:

**Netlify** (`netlify.toml`) or **Cloudflare Pages** (`public/_headers`):

```
/*
  Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  X-Frame-Options: DENY
  Permissions-Policy: camera=(), microphone=(), geolocation=()
```

GitHub Pages cannot set custom headers at all — if item 26 matters, the site needs
a CDN in front or a different host. Say that plainly rather than reporting a fix
that the platform will ignore.

A `<meta http-equiv="Content-Security-Policy">` tag is a partial fallback: it
cannot express `frame-ancestors` or HSTS, so it never fully substitutes for real
headers. Verify what is actually served:

```bash
curl -sI https://example.com | rg -i 'strict-transport|content-security|x-frame|referrer'
```

## Forms (24, 25)

A static site has no server, so form handling goes to a third party — Netlify Forms,
Formspree, a serverless function. Two consequences for the audit:

- **Item 24**: validation must exist on whatever receives the POST. If the endpoint
  is a third-party service, check what it validates; if the answer is "nothing", the
  item fails regardless of the client-side checks.
- **Item 6**: that endpoint is a data recipient, so it belongs in the privacy
  policy's processor list, and often needs a data processing agreement.

Netlify Forms supports a honeypot (`netlify-honeypot="bot-field"`) and offers a
captcha; both are enforced server-side. A `required` attribute is not validation —
it is a hint the client can remove in devtools in one keystroke.

## Performance (20)

Static sites usually pass on LCP unless something specific goes wrong. The usual
culprits, in order:

- Render-blocking `@import` in CSS, or a webfont loaded without `font-display: swap`.
- Full-resolution hero images served unresized. Ship modern formats and correct
  intrinsic dimensions — this also prevents the layout shift.
- A client-side router hydrating the whole app before first paint.
- Third-party embeds in `<head>`, which also fail item 5 by loading pre-consent.

Self-hosting fonts fixes a performance problem and a consent problem at once.
