# Laravel / Blade — where each item lives

## Where to look

| Items | Location |
|---|---|
| 1–4, 22 | `resources/views/legal/*.blade.php`, `resources/views/errors/404.blade.php` |
| 5, 6 | the layout in `resources/views/layouts/`, any `@vite`/`<script>` in `<head>` |
| 10 | the footer partial included by the layout |
| 12–15 | every Blade view with a form, and the components in `resources/views/components/` |
| 16 | `config/*.php` reaching `env()`, and anything Vite exposes via `VITE_*` |
| 17, 18 | `@section('title')` / `@stack('meta')` per view |
| 19 | `public/robots.txt`, the sitemap route or generator |
| 24, 25 | `app/Http/Requests/*`, `routes/web.php` middleware |
| 26 | `app/Http/Middleware/`, or the web-server config |

## Secrets and env (16)

The Laravel-specific trap is `env()` called **outside** `config/`. Once
`php artisan config:cache` runs in production — and it should — those calls return
`null`, so the code silently falls back rather than failing loudly. Every `env()`
read belongs in a config file; application code reads `config('services.x.key')`.

```bash
rg -n 'env\(' app/ routes/ resources/ --glob '!config/*'
```

Then check what Vite publishes. Anything prefixed `VITE_` is compiled into the
client bundle and is public:

```bash
rg -n 'VITE_' .env.example resources/js/
```

Confirm `.env` is gitignored and not tracked (`git ls-files | rg '\.env$'`), and
that `APP_DEBUG=false` and `APP_ENV=production` in the production environment —
a debug-mode stack trace leaks paths, config and sometimes credentials.

## Forms (24, 25)

Validation belongs in a `FormRequest`, not the controller body, so it cannot be
skipped by a second entry point to the same action:

```php
class ContactRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name'    => ['required', 'string', 'max:100'],
            'email'   => ['required', 'email:rfc,dns', 'max:255'],
            'message' => ['required', 'string', 'max:2000'],
            'consent' => ['accepted'],          // item 7 — must be ticked, never pre-ticked
            'website' => ['prohibited'],        // item 25 — honeypot; bots fill it, humans cannot see it
        ];
    }
}
```

`prohibited` on a hidden field is a clean honeypot: it fails validation server-side
whenever a bot fills it, with no client-side logic to bypass.

Rate limiting is middleware, applied at the route:

```php
Route::post('/contact', ContactController::class)
    ->middleware('throttle:5,1');   // 5 requests per minute per IP
```

Check the throttle is actually attached to every public POST route — an unthrottled
one beside three throttled ones is the usual finding.

Blade escapes with `{{ }}`; `{!! !!}` does not. Every `{!! !!}` over user-supplied
data is an XSS finding:

```bash
rg -n '\{!!' resources/views/
```

## Errors and 404 (22)

`resources/views/errors/404.blade.php` is picked up automatically and returns the
right status. The soft-404 risk here is a controller that catches a missing model
and renders a normal view with 200 — use `abort(404)` or route-model binding, which
throws `ModelNotFoundException` and resolves to a real 404.

## Headers (26)

Laravel ships no security headers by default. Add middleware and register it on the
`web` group:

```php
public function handle(Request $request, Closure $next): Response
{
    $response = $next($request);

    $response->headers->add([
        'Strict-Transport-Security' => 'max-age=63072000; includeSubDomains; preload',
        'X-Content-Type-Options'    => 'nosniff',
        'Referrer-Policy'           => 'strict-origin-when-cross-origin',
        'X-Frame-Options'           => 'DENY',
        'Permissions-Policy'        => 'camera=(), microphone=(), geolocation=()',
    ]);

    return $response;
}
```

Check `config/session.php`: `secure` true in production, `http_only` true,
`same_site` at least `lax`. A session cookie without `secure` is sent over plain
HTTP if any path reaches one.

Also confirm `TrustProxies` is configured when behind a load balancer — without it
Laravel sees HTTP, generates HTTP URLs, and the HTTPS redirect can loop.

## Metadata (17, 18)

Usually a `@section('title')` with a layout default. Verify each route sets its own
rather than inheriting — inherited titles across many routes are `⚠️ PARTIAL`.
Localised sites should emit `hreflang` alternates alongside the canonical.
