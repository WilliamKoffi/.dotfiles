#!/usr/bin/env bash
# preflight scan — read-only evidence gathering for the 26-item pre-launch audit.
# Writes nothing, mutates nothing. Every hit is a file:line a human can open.
#
# Usage: scan.sh [path] [section]
#   section: all (default) | stack secrets trackers consent legal meta crawl
#            alt labels forms spam headers a11y claims perf
#
# Backed by ripgrep, so .gitignore is honoured automatically: build output,
# node_modules and scratch dirs are skipped, untracked source files are not.
#
# Absence of a hit is NOT evidence of a pass — it is a prompt to go look.

set -uo pipefail

ROOT="${1:-.}"
ONLY="${2:-all}"
cd "$ROOT" 2>/dev/null || { echo "preflight: cannot enter '$ROOT'" >&2; exit 1; }
command -v rg >/dev/null 2>&1 || { echo "preflight: ripgrep (rg) is required" >&2; exit 1; }

RG=(rg --line-number --no-heading --color=never --no-messages
    --max-filesize 1M --max-columns 240 --max-columns-preview)

GLOBS=(-g '*.ts' -g '*.tsx' -g '*.js' -g '*.jsx' -g '*.mjs' -g '*.cjs'
       -g '*.vue' -g '*.svelte' -g '*.astro' -g '*.html' -g '*.htm'
       -g '*.php' -g '*.mdx' -g '*.erb' -g '*.twig' -g '*.liquid'
       -g '!*.min.js' -g '!*.min.css' -g '!*-lock.*' -g '!*.map')

# Shipped surface only: test fixtures are not user-facing, and their sample
# markup (deliberately broken <img>, fake keys) otherwise floods the findings.
SHIPPED=(-g '!*.test.*' -g '!*.spec.*' -g '!**/tests/**' -g '!**/__tests__/**'
         -g '!**/e2e/**' -g '!**/fixtures/**')

want() { [ "$ONLY" = all ] || [ "$ONLY" = "$1" ]; }
sec()  { printf '\n\n===== %s =====\n' "$1"; }
emit() {
  local out; out="$(cat)"
  if [ -n "$out" ]; then printf '%s\n' "$out" | sed 's/^/  /'
  else echo "  (none found)"; fi
}

g()    { "${RG[@]}" "${GLOBS[@]}" "${SHIPPED[@]}" -e "$1" . 2>/dev/null | head -"${2:-40}"; }
gi()   { "${RG[@]}" -i "${GLOBS[@]}" "${SHIPPED[@]}" -e "$1" . 2>/dev/null | head -"${2:-40}"; }
gp()   { "${RG[@]}" -P "${GLOBS[@]}" "${SHIPPED[@]}" -e "$1" . 2>/dev/null | head -"${2:-40}"; }
gm()   { "${RG[@]}" -UP "${GLOBS[@]}" "${SHIPPED[@]}" -e "$1" . 2>/dev/null | head -"${2:-40}"; }
gsec() { "${RG[@]}" "${GLOBS[@]}" -e "$1" . 2>/dev/null | head -"${2:-40}"; }
lsf(){ rg --files --glob-case-insensitive -g "$1" . 2>/dev/null | head -"${2:-30}"; }

echo "preflight scan — $(pwd)"
echo "generated $(date -u '+%Y-%m-%d %H:%M UTC') — read-only, nothing was modified"

# ------------------------------------------------------------------ stack
if want stack || want all; then
sec "STACK SIGNALS"
{
  for m in package.json composer.json requirements.txt Gemfile go.mod \
           next.config.js next.config.ts next.config.mjs nuxt.config.ts \
           svelte.config.js astro.config.mjs vite.config.ts artisan \
           vercel.json vercel.ts netlify.toml; do
    [ -e "$m" ] && echo "$m"
  done
  for d in app src/app pages src/pages resources/views; do
    [ -d "$d" ] && echo "$d/ (dir)"
  done
} | emit
{ rg --no-messages -N '"(next|nuxt|astro|svelte|vue|react|laravel/framework)":' \
    package.json composer.json 2>/dev/null | head -12; } | emit
fi

# -------------------------------------------------------------- 16 secrets
if want secrets || want all; then
sec "16. CLIENT-EXPOSED ENV + HARDCODED SECRETS"
echo "-- public-prefixed env reads (these ship to the browser) --"
gsec 'process\.env\.(NEXT_PUBLIC|PUBLIC)_[A-Z0-9_]+|import\.meta\.env\.(VITE|PUBLIC)_[A-Z0-9_]+|VUE_APP_[A-Z0-9_]+' 60 | emit
echo "-- public-prefixed names that read like credentials --"
gsec '(NEXT_PUBLIC|PUBLIC|VITE|VUE_APP)_[A-Z0-9_]*(SECRET|PRIVATE|TOKEN|PASSWORD|API_?KEY|ACCESS_?KEY|DSN|CREDENTIAL|SERVICE_ROLE)' 40 | emit
echo "-- literal key shapes in source --"
gsec '(sk_live_|sk_test_|rk_live_|xoxb-|xoxp-|ghp_|github_pat_|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJhbGciOi[A-Za-z0-9_-]{20,})' 40 | emit
echo "-- env files tracked by git (should be none except .env.example) --"
{ git ls-files 2>/dev/null | rg '(^|/)\.env' | rg -v '\.example$' | head -20; } | emit
echo "-- .gitignore coverage for env files --"
{ rg -n '\.env' .gitignore 2>/dev/null | head -10; } | emit
fi

# ------------------------------------------------------------- 6 trackers
if want trackers || want all; then
sec "6. TRACKER + THIRD-PARTY SCRIPT INVENTORY"
gi 'googletagmanager|google-analytics|gtag\(|dataLayer|facebook\.net|fbq\(|hotjar|clarity\.ms|segment\.(com|io)|mixpanel|amplitude|posthog|plausible|umami|matomo|fathom|intercom|crisp\.chat|drift\.com|linkedin.{0,10}insight|doubleclick\.net|adsbygoogle|sentry|@vercel/analytics|@vercel/speed-insights|SpeedInsights|<Analytics[\s/>]' 60 | emit
echo "-- external script tags / framework script components --"
g '<script[^>]+src=.https?://|next/script|<Script ' 40 | emit
echo "-- external iframes (maps, video, widgets set cookies too) --"
g '<iframe[^>]+src=.https?://' 30 | emit
fi

# -------------------------------------------------------------- 5 consent
if want consent || want all; then
sec "5. COOKIE CONSENT MACHINERY"
gi 'cookie.?consent|CookieBanner|consentMode|consent_mode|osano|cookiebot|onetrust|klaro|tarteaucitron|termly|iubenda|vanilla-cookieconsent|cookieyes' 40 | emit
echo "-- cookie writes --"
g 'document\.cookie|cookies\(\)\.set|setCookie|res\.cookie|Set-Cookie' 40 | emit
echo "-- storage writes (consent-bearing under ePrivacy too) --"
g '(localStorage|sessionStorage)\.setItem' 30 | emit
fi

# -------------------------------------------------------- 1-4,10,22 pages
if want legal || want all; then
sec "1-4, 10, 22. LEGAL / TRUST / 404 PAGES ON DISK"
{ for p in '*privacy*' '*terms*' '*cookie*' '*refund*' '*legal*' '*imprint*' \
           '*impressum*' '*mentions*legales*' '*cgv*' '*cgu*' \
           '*not-found*' '404*' '*disclaimer*'; do lsf "$p" 12; done | sort -u; } | emit
echo "-- links to legal routes in markup --"
gi 'href=.[^"'"'"']*(privacy|terms|cookie|refund|legal|imprint|impressum|mentions|cgv|cgu)' 40 | emit
echo "-- business identity strings (entity / registration / VAT) --"
g '(SIRET|SIREN|VAT|TVA|RCS|Company No|Registered (office|in)|Reg\. No|EIN)' 30 | emit
echo "-- contact affordances --"
g 'href=.mailto:|href=.tel:' 30 | emit
fi

# ------------------------------------------------------------- 17,18 meta
if want meta || want all; then
sec "17, 18. TITLES / DESCRIPTIONS / OPEN GRAPH"
echo "-- metadata exports & titles --"
g 'export const metadata|generateMetadata|<title>|useSeoMeta|useHead\(|<Helmet|document\.title' 50 | emit
echo "-- description tags --"
g 'name=.description|description:\s*["'"'"'`]' 40 | emit
echo "-- open graph / twitter card --"
g 'og:(title|description|image|url|type)|openGraph|twitter:(card|image|title)' 40 | emit
echo "-- og image assets present? --"
{ for p in 'og*image*' '*opengraph*' 'twitter-image*'; do lsf "$p" 10; done | sort -u; } | emit
fi

# ------------------------------------------------------------ 19,22 crawl
if want crawl || want all; then
sec "19, 22. ROBOTS / SITEMAP / 404 / CANONICAL"
{ for p in 'robots*' 'sitemap*' 'not-found.*' '404.*'; do lsf "$p" 10; done | sort -u; } | emit
echo "-- noindex / disallow-all (blocks launch if left on) --"
gi 'noindex|X-Robots-Tag|Disallow: /$' 30 | emit
echo "-- canonical --"
g 'rel=.canonical|canonical:' 25 | emit
fi

# ---------------------------------------------------------------- 13 alt
if want alt || want all; then
sec "13. IMAGES WITHOUT ALT"
echo "-- img/Image tags with no alt= anywhere inside the tag (multiline aware) --"
gm '<(?:img|Image)\b(?:(?!alt=)[\s\S])*?/?>' 50 | emit
echo "-- decorative alt=\"\" (legitimate only if truly decorative — confirm each) --"
g 'alt=("" |""|\{""\})' 30 | emit
echo "-- CSS background images (invisible to AT; need a text alternative if meaningful) --"
g 'background-image:|bg-\[url\(' 25 | emit
fi

# ------------------------------------------------------------- 14 labels
if want labels || want all; then
sec "14. VAGUE LINK / BUTTON LABELS"
g '>\s*(Click here|click here|Read more|Learn more|More|Submit|Send|Go|OK|Continue|Next|Start|Try it|Get started|Download|View|See more|Details)\s*<' 50 | emit
echo "-- icon-only controls (need an accessible name) --"
gm '<button\b(?:(?!aria-label)[\s\S])*?>\s*<(?:svg|Icon|i\s)' 30 | emit
echo "-- aria-label usage --"
g 'aria-label=' 30 | emit
fi

# --------------------------------------------------- 7,11,12,15,24 forms
if want forms || want all; then
sec "7, 11, 12, 15, 24. FORMS / INPUTS / LABELS / CONSENT BOXES"
echo "-- form elements --"
g '<form|useForm|<Form |handleSubmit|method=.post' 40 | emit
echo "-- inputs (every field must justify itself under data minimization) --"
g '<(input|textarea|select|Input|Textarea|Select)\s' 60 | emit
echo "-- label association --"
g 'htmlFor=|<label|aria-labelledby=|aria-describedby=' 40 | emit
echo "-- checkboxes + pre-checked state (consent must be unchecked) --"
g 'type=.checkbox|defaultChecked|checked=\{true\}' 40 | emit
echo "-- consent-ish copy near forms --"
gi 'I agree|I accept|consent|opt.?in|newsletter|subscribe' 40 | emit
fi

# ------------------------------------------------------------ 24,25 spam
if want spam || want all; then
sec "24, 25. SERVER-SIDE VALIDATION / RATE LIMIT / CAPTCHA / HONEYPOT"
echo "-- schema validation --"
g 'zod|z\.object|yup|joi|valibot|class-validator|FormRequest|->validate\(|Validator::make' 40 | emit
echo "-- rate limiting --"
gi 'rate.?limit|throttle|@upstash/ratelimit|express-rate-limit' 40 | emit
echo "-- captcha / bot defence --"
gi 'recaptcha|hcaptcha|turnstile|cf-turnstile|botid|altcha' 30 | emit
echo "-- honeypot --"
gi 'honeypot|honey_pot|_gotcha|bot-field' 20 | emit
fi

# ---------------------------------------------------------- 26 headers
if want headers || want all; then
sec "26. SECURITY HEADERS / HTTPS"
g 'Strict-Transport-Security|Content-Security-Policy|X-Frame-Options|X-Content-Type-Options|Referrer-Policy|Permissions-Policy|frame-ancestors|upgrade-insecure-requests' 40 | emit
echo "-- header config surfaces present --"
{ for m in next.config.js next.config.ts next.config.mjs vercel.json vercel.ts \
           middleware.ts middleware.js netlify.toml public/_headers .htaccess nginx.conf; do
    [ -e "$m" ] && echo "$m"
  done; } | emit
echo "-- plain http:// references (mixed-content risk) --"
gp 'http://(?!localhost|127\.0\.0\.1|0\.0\.0\.0|schema\.org|www\.w3\.org|purl\.org|ns\.adobe)' 30 | emit
fi

# ------------------------------------------------------------ 12,15 a11y
if want a11y || want all; then
sec "12, 15. ACCESSIBILITY SMELLS"
echo "-- positive tabindex (breaks natural tab order) --"
g 'tabIndex=\{?[1-9]|tabindex=.[1-9]' 25 | emit
echo "-- click handlers on non-interactive elements --"
g '<(div|span|li|td|p)[^>]*onClick' 40 | emit
echo "-- focus suppression --"
g 'outline:\s*(none|0)|outline-none' 30 | emit
echo "-- landmarks / roles / live regions --"
g 'role=.|aria-live=|<main|<nav|<header|<footer' 40 | emit
echo "-- dialogs (need focus trap, Esc, aria-modal, return focus) --"
g 'Dialog|Modal|role=.dialog|aria-modal' 30 | emit
echo "-- skip link --"
gi 'skip.?to.?(main|content)|#main-content' 15 | emit
echo "-- lang attribute --"
g '<html[^>]*lang=|lang=["'"'"'{]' 20 | emit
fi

# ------------------------------------------------------------- 9 claims
if want claims || want all; then
sec "9. MARKETING CLAIMS TO VERIFY AGAINST A REAL SOURCE"
gi '[0-9][0-9,.]*\s*(%|percent)|[0-9][0-9,.]*\+?\s*(users|customers|clients|companies|resumes|downloads|reviews)|#1|No\.? 1|trusted by|loved by|guarantee|guaranteed|instantly|in seconds|best.in.class|award.winning|industry.leading|proven to' 60 | emit
fi

# ----------------------------------------------------------- 20,21 perf
if want perf || want all; then
sec "20, 21. PERFORMANCE / RESPONSIVE SIGNALS"
echo "-- raw <img> (bypasses the framework image optimizer) --"
g '<img ' 30 | emit
echo "-- loading / priority hints --"
g 'loading=.lazy|priority|fetchPriority|preload|decoding=' 30 | emit
echo "-- font loading --"
g 'next/font|@font-face|fonts\.googleapis|font-display' 30 | emit
echo "-- viewport meta --"
g 'name=.viewport|viewport:|width=device-width' 20 | emit
echo "-- fixed widths / overflow risks --"
g 'width:\s*[0-9]{3,}px|w-\[[0-9]{3,}px\]|overflow-x' 30 | emit
fi

printf '\n\nscan complete — nothing was modified.\n'
