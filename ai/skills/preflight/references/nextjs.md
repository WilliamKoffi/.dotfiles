# Next.js (App Router) — where each item lives

Paths assume `app/` or `src/app/`. Adjust for a `src/` prefix and for route groups.

## Where to look

| Items | Location |
|---|---|
| 1–4, 22 | `app/(legal)/privacy/page.tsx` etc.; `app/not-found.tsx` |
| 5, 6 | root `app/layout.tsx`, any `next/script`, `@vercel/analytics` |
| 10 | the footer component rendered by the root layout |
| 12–15 | every `page.tsx` / client component with a form or dialog |
| 16 | `NEXT_PUBLIC_*` reads, and `.next/static/**` in the built output |
| 17, 18 | `metadata` / `generateMetadata` exports per route |
| 19 | `app/robots.ts`, `app/sitemap.ts` |
| 24, 25 | `app/api/**/route.ts`, server actions |
| 26 | `next.config.*` headers, `middleware.ts` |

## Metadata (17, 18)

`metadata` is static; `generateMetadata` is for dynamic routes. Set `metadataBase`
once in the root layout so OG image paths resolve absolutely — a relative OG URL is
the most common cause of a preview that renders locally and breaks on Twitter.

```ts
// app/layout.tsx
export const metadata: Metadata = {
  metadataBase: new URL('https://example.com'),
  title: { default: 'Site name', template: '%s · Site name' },
  description: '…150–160 chars…',
  openGraph: { type: 'website', images: [{ url: '/og.png', width: 1200, height: 630 }] },
  twitter: { card: 'summary_large_image' },
};
```

A `title.template` in the root plus a per-route `title` satisfies uniqueness.
Routes inheriting the default title wholesale are `⚠️ PARTIAL` for item 17.

File conventions (`app/opengraph-image.tsx`, `app/icon.png`) generate the tags
automatically — check for those before reporting the tags missing.

## robots and sitemap (19)

Prefer `app/robots.ts` and `app/sitemap.ts` over static files in `public/` — they
cannot drift from the route list. Verify the sitemap enumerates *real* routes; a
hand-maintained array that has fallen behind is `⚠️ PARTIAL`.

Check for an environment-conditional `noindex`. A preview-only guard that reads the
wrong env var in production is a launch blocker and looks correct on inspection —
confirm against the production environment, not the source.

## 404 (22)

`app/not-found.tsx` returns a real 404 for unmatched routes. But a dynamic route
that renders an "not found" UI itself returns **200** — a soft-404. Call
`notFound()` from `next/navigation` instead so the status is right.

## Security headers (26)

Static headers go in `next.config.*`; a nonce-based CSP needs `middleware.ts`,
since the nonce must be generated per request.

```js
// next.config.mjs
async headers() {
  return [{ source: '/:path*', headers: [
    { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
    { key: 'X-Content-Type-Options', value: 'nosniff' },
    { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
    { key: 'X-Frame-Options', value: 'DENY' },
    { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
  ]}];
}
```

Next injects inline scripts for hydration, so a CSP without a nonce will need
`unsafe-inline` — report that as `⚠️ PARTIAL` with the nonce migration as the path
out, rather than pretending the header is complete.

## Secrets (16)

`NEXT_PUBLIC_*` is compiled into the client bundle. Any credential behind that
prefix is public from its first deploy — a rotation task, not just an edit.

Grep the build output, not only the source, since indirection hides reads:

```bash
rg -o 'sk_live_[A-Za-z0-9]+|AIza[0-9A-Za-z_-]{20,}' .next/static -r '$0' | sort -u
```

Publishable keys (Stripe `pk_`, a restricted Maps key, a Supabase anon key) are
*designed* to be public — do not report them as leaks. Check the key's own
restrictions instead: an unrestricted Maps browser key is a real finding.

## Forms (24, 25)

Server actions and route handlers both need their own validation — the action
being colocated with the component does not make it trusted. Parse with a schema
at the boundary:

```ts
const parsed = ContactSchema.safeParse(Object.fromEntries(formData));
if (!parsed.success) return { errors: parsed.error.flatten().fieldErrors };
```

Rate limiting belongs in the handler or middleware; `@upstash/ratelimit` is the
common fit on serverless, where in-memory counters do not survive across instances.
An in-memory limiter on Vercel is effectively no limiter — worth flagging.

## Performance (20)

`next/image` with `priority` on the LCP image only; `next/font` to self-host and
avoid a layout shift (and to drop a consent category, per item 5). Check what is
in the client bundle — a `'use client'` boundary placed too high pulls the tree
with it, and is the usual cause of a slow LCP in an otherwise clean app.
