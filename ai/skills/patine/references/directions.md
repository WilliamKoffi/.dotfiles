# Directions and tokens

## Finding three directions worth comparing

Three options help only if each one is a real bet. Place each direction on these
axes, and make sure every pair differs on at least two of them:

| Axis | One end | Other end |
|---|---|---|
| Temperature | warm (earth, cream, terracotta) | cool (stone, ink, steel) |
| Contrast | soft, tonal | stark, graphic |
| Type voice | serif / editorial | grotesk / modern, or a characterful display face |
| Density | airy, few items, big images | dense, catalogue-like |
| Shape | sharp, straight lines | rounded, organic, arches |
| Ornament | none, pure content | texture, grain, illustration, pattern |
| Motion | still, instant | choreographed, slow easing |

Where the ideas come from, roughly in this order:

1. **The product itself**: its material, its origin, how it is made (linen gives
   texture, weave, undyed tones).
2. **The audience and the place**: local visual culture, the climate, the language,
   the price level. A luxury brand in Abidjan is not one in Oslo.
3. **What must be kept** (`concept.md` → Keep): a logo colour can anchor one
   direction, or be reframed by another.
4. **Category conventions**: one direction can follow them (safe, familiar) and one
   can break them on purpose. Say which one does which.

For each direction write:

```
### A « <name> »
Thesis: <one line: the feeling, and how it gets there>
Fits because: <2–3 points, each citing concept.md>
Palette: <role → hex, with a reason for the accent>
Type: <display / body, from Google Fonts, the scale ratio>
Shape & space: <radius, borders, density>
Imagery & texture: <photo treatment, grain, patterns>
Motion: <easing, what moves>
Voice: <one real sample line, e.g. a CTA and a hero line>
Risk: <what could go wrong: too cold, dated soon, hard to read on phones…>
```

End with a recommendation (which one, and why), then let the user decide.

## Tokens

`theme.js` holds `THEMES`: one entry per candidate during the brainstorm, and only
`main` once a theme is chosen. Every theme has the same keys, because the pages and
`scripts/contrast.mjs` rely on them.

| Key | Meaning |
|---|---|
| `colors.bg` | page background |
| `colors.surface` | cards, drawers, inputs |
| `colors.ink` | main text |
| `colors.muted` | secondary text (must still pass AA on `bg` and `surface`) |
| `colors.line` | borders and dividers |
| `colors.accent` | primary action, links, highlights |
| `colors.accentInk` | text on `accent` |
| `colors.*` | extra roles as needed (`accent2`, `success`, `danger`, `sale`) |
| `fonts.display`, `fonts.body` | font-family stacks |
| `fontsHref` | the Google Fonts URL that loads them |
| `radius.control`, `radius.card` | buttons and fields; cards and images |
| `shadow` | the one elevation used for overlays |
| `ease`, `duration` | default motion |

Name roles by use, never by colour (`accent`, not `terracotta`). That way a palette
change doesn't make a class name lie.
