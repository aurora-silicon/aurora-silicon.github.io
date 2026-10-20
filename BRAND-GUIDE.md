# Aurora Silicon brand guide

Aurora Silicon brings Windows and Linux to Apple Silicon Macs; the two are equal sub-projects under one master mark. The positioning line used in this kit is "Windows and Linux on Apple Silicon" (change it in one place in `work/build_brand_kit.py` if the wording changes). This kit contains the master mark, the two
sub-project marks, colour tokens, favicons, a social preview image and a homepage example.

## 1. The master mark

An upright, symmetric geometric **A** of uniform band width with a single-period **wave crossbar**
that passes over the left leg and under the right leg. The wave is the only device: it carries the
"S" of Aurora Silicon and the aurora idea. The flow runs warm to cool from left to right: sunlit
orange at the left foot, pearl at the apex, indigo at the right foot.

Files:

- `svg/aurora-silicon-mark.svg` - full-colour, inline-safe (all ids prefixed `as-mark-`, no editor
  metadata, `viewBox` only so it scales with CSS). Use this in the hero and navigation.
- `svg/aurora-silicon-mark-mono.svg` - one-colour silhouette filled with `currentColor`. Use for
  footers, monochrome contexts, print, embroidery, and anywhere the gradient would fight the layout.
- `png/aurora-silicon-mark-{64..1024}.png` - transparent renders for places that cannot take SVG.
- The editable Inkscape master is `../aurora-silicon-master-mark.svg` (built by
  `work/build_aurora-silicon-master-geo.py`).

## 2. Colour

| Token | Hex | Use |
|---|---|---|
| `--as-orange` | #FF992A | warm end of the flow, highlights, primary accent on dark |
| `--as-peach` | #F3BD91 | flow |
| `--as-pearl` | #EAD1C8 | flow midpoint, apex of the mark |
| `--as-cream` | #FFF3DA | text on dark grounds, highlight lines |
| `--as-lavender` | #AAA6C8 | flow, muted text on dark |
| `--as-periwinkle` | #7F81B3 | flow |
| `--as-royal` | #6278D7 | flow, links on dark |
| `--as-cobalt` | #4E66C5 | flow |
| `--as-deep` | #2240AB | flow, theme colour, buttons on light |
| `--as-indigo` | #001478 | cool end of the flow, deepest shadow |
| `--as-ground-dark` | #141626 | default site ground (indigo-tinted near-black) |
| `--as-ground-light` | #F4F4F4 | light ground |

The flow as a gradient: `--as-flow` in `css/aurora-silicon-brand.css`. Use it for thin rules,
primary buttons and gradient text on dark grounds. Do not use it as a full-page background: it
competes with the mark.

Contrast: cream (#FFF3DA) on the dark ground and #141626 on the light ground both exceed WCAG AA for
body text. Do not set body text in the mid-flow colours (peach, pearl, lavender) on light grounds.

## 3. Placement rules

- **Clear space**: keep at least 0.25 x the mark's height free on every side (that equals the band width).
- **Minimum size**: 32 px tall for the full-colour mark on screen; 24 px for the mono mark; 16 px is
  favicon only. Never scale below 16 px.
- **Grounds**: tested on #141626 / #202020 (dark) and #F4F4F4 (light). On photos or busy grounds use
  the mono mark or put the full-colour mark on a plain panel.
- **Do not** rotate, skew, add perspective, add drop shadows or glows, recolour the gradient, outline
  the mark, stretch it, or place text inside the counter. Do not rebuild the mark from type: the A is
  drawn geometry, not a font glyph.
- **Lockup**: the mark sits to the left of the wordmark, centred on the wordmark's x-height, with a
  gap equal to half the mark's height. The wordmark is set in a clean geometric sans (Inter, Segoe UI
  or the system sans), weight 600, tight tracking. The brand has no bespoke typeface yet.

## 4. Sub-project marks

- **Windows sub-project**: the four-panel bowed-flag mark. `sub-projects/aurora-silicon-windows-mark.svg` is the
  web version (each satin surface's mesh gradient fitted to a linear gradient; masks and a blur filter remain, which
  all current browsers render). `sub-projects/aurora-silicon-windows-mark-editable-mesh.svg` is the Inkscape master
  with the original mesh gradients for editing and print; browsers will not render its meshes. PNGs at 256 and 512 too.
- **Linux sub-project**: the Tux silhouette with the bite out of the belly
  (`sub-projects/aurora-silicon-linux-mark.svg` and PNGs). The SVG uses masks and a blur filter, which
  all current browsers render.
- Both share the master mark's flow, satin folds, highlight lines and hairline rim. Windows and Linux are peers: show them together at equal size, in that order or alphabetical, never one above the other. Use them only for
  their sub-projects, never in place of the master mark.

## 5. Favicons and app icons

`favicon/` holds `favicon.svg`, `favicon.ico` (16/32/48), `favicon-16/32/48.png`, `apple-touch-icon.png`
(180), `icon-192.png`, `icon-512.png` and `site.webmanifest`. Head tags are in
`html/homepage-example.html`. The app icons are the mark on a transparent square; if a store requires
an opaque tile, use `--as-ground-dark` behind the mark with the standard clear space.

## 6. Social preview

`social/og-image.png` (1200 x 630): the mark and wordmark on the dark ground with a soft aurora glow.
Reference it from `og:image`.

## 7. Homepage

`html/homepage-example.html` shows the intended use: the inline full-colour mark as the hero focal
point, the mark at 32 px in the navigation, a flow-gradient rule and button, and the mono mark in the
footer. Copy the head tags, the CSS file and the inline SVG into your site; the example expects the
kit's folder structure.
