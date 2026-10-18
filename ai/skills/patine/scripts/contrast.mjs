#!/usr/bin/env node
// WCAG 2.2 contrast check of every theme in a playground's theme.js.
//   bun contrast.mjs trash/playground/<ctx>/theme.js
// Exit code 1 if any pair fails.
import { readFileSync } from 'node:fs'
import vm from 'node:vm'

const file = process.argv[2]
if (!file) { console.error('usage: contrast.mjs <theme.js>'); process.exit(2) }
const THEMES = vm.runInNewContext(`${readFileSync(file, 'utf8')}\n;THEMES`, {})

const lum = (hex) => {
  let h = hex.replace('#', '')
  if (h.length === 3) h = [...h].map((c) => c + c).join('')
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16) / 255)
    .map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4))
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}
const ratio = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((m, n) => n - m); return (x + 0.05) / (y + 0.05) }

// [foreground, background, minimum, what it is]
const PAIRS = [
  ['ink', 'bg', 4.5, 'body text'],
  ['ink', 'surface', 4.5, 'text on cards'],
  ['muted', 'bg', 4.5, 'secondary text'],
  ['muted', 'surface', 4.5, 'secondary text on cards'],
  ['accentInk', 'accent', 4.5, 'button label'],
  ['accent', 'bg', 3, 'links / UI on page'],
  ['accent', 'surface', 3, 'links / UI on cards'],
  ['line', 'bg', 1.2, 'dividers visible (advisory)'],
]

let failed = 0
for (const [key, t] of Object.entries(THEMES)) {
  console.log(`\n${key} — ${t.name}`)
  for (const [fg, bg, min, what] of PAIRS) {
    const [a, b] = [t.colors[fg], t.colors[bg]]
    if (!a || !b) { console.log(`  MISSING  ${fg}/${bg}`); failed++; continue }
    const r = ratio(a, b)
    const ok = r >= min
    if (!ok && min > 1.2) failed++
    console.log(`  ${ok ? 'PASS' : min > 1.2 ? 'FAIL' : 'WARN'}  ${r.toFixed(2).padStart(5)} ≥ ${min}  ${fg} on ${bg}  (${what})`)
  }
}
process.exit(failed ? 1 : 0)
