// The theme: the one source of truth for every page in this playground.
// Brainstorm: one entry per candidate (a, b, c). After the choice: only `main`.
// Keys are fixed (see references/directions.md → Tokens); contrast.mjs reads them.
const THEMES = {
  a: {
    name: 'A « … »',
    colors: {
      bg: '#FAF8F5', surface: '#FFFFFF', ink: '#1A1816', muted: '#5F5A53', line: '#E4DED4',
      accent: '#9C4A33', accentInk: '#FFFFFF',
    },
    fonts: { display: ['"Playfair Display"', 'Georgia', 'serif'], body: ['Inter', 'system-ui', 'sans-serif'] },
    fontsHref: 'https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,500;1,400&family=Inter:wght@400;500;600&display=swap',
    radius: { control: '999px', card: '12px' },
    shadow: '0 12px 40px -12px rgb(0 0 0 / .25)',
    ease: 'cubic-bezier(.22,1,.36,1)', duration: '400ms',
  },
}

// ---- browser side: pick the theme, load its fonts, expose tokens to Tailwind and CSS ----
if (typeof window !== 'undefined') {
  const params = new URLSearchParams(location.search)
  const key = params.get('theme') in THEMES ? params.get('theme') : Object.keys(THEMES)[0]
  const T = (window.THEME = THEMES[key])
  window.THEMES = THEMES
  window.THEME_KEY = key

  const link = document.createElement('link')
  link.rel = 'stylesheet'
  link.href = T.fontsHref
  document.head.appendChild(link)

  const vars = Object.entries(T.colors).map(([k, v]) => `--t-${k}:${v};`).join('')
  const style = document.createElement('style')
  style.textContent = `:root{${vars}--t-ease:${T.ease};--t-duration:${T.duration}}
body{background:var(--t-bg);color:var(--t-ink);font-family:${T.fonts.body.join(',')};-webkit-font-smoothing:antialiased}
@media (prefers-reduced-motion: reduce){*,*::before,*::after{animation-duration:.01ms!important;transition-duration:.01ms!important}}`
  document.head.appendChild(style)

  // Classes: bg-t-bg, text-t-ink, border-t-line, font-display, rounded-control, shadow-t …
  if (window.tailwind) {
    window.tailwind.config = {
      theme: {
        extend: {
          colors: { t: Object.fromEntries(Object.keys(T.colors).map((k) => [k, `var(--t-${k})`])) },
          fontFamily: { display: T.fonts.display, body: T.fonts.body },
          borderRadius: T.radius,
          boxShadow: { t: T.shadow },
          transitionTimingFunction: { t: T.ease },
        },
      },
    }
  }
}
