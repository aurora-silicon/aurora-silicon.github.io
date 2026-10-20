# Aurora Silicon website

Aurora’s Linux-first project website, built with Astro and Starlight. The monochrome homepage lives at `/`; documentation lives at `/docs/`. Light and dark themes share the same preference. Color is reserved for the Aurora mark and feature status tints.

## Development

Use Node.js 22.12 or later.

```sh
npm ci
npm run dev
```

Before committing:

```sh
npm run check
npm run build
```

To serve the production build locally, use `npm run preview`.

On Linux ARM64 with a page size above 4 KB (including Apple Silicon’s 16 KB kernels), the build script compiles a matching native Pagefind once and caches it in `.cache/`. This requires Rust/Cargo on that machine. Other platforms use Starlight’s bundled binary. An existing `PAGEFIND_BINARY_PATH` or `PAGEFIND_EXTENDED_BINARY_PATH` is respected.

## Structure

- `src/pages/index.astro`: custom homepage, with Linux as the primary focus.
- `src/content/docs/docs/`: Markdown documentation served by Starlight.
- `src/styles/brand.css`: original Aurora brand tokens.
- `src/styles/home.css`: monochrome homepage layout and responsive styles.
- `src/components/MacBook.astro`: vector MacBook illustration with the official A mark.
- `src/pages/devices.astro`: standalone SoC and device-class feature support page.
- `src/pages/download.astro`: redirect to the Omarchy Mac download section.
- `src/layouts/Site.astro`: shared minimal header, metadata, and social links.
- `src/components/DeviceFinder.astro`: device and SoC selection, feature pills, and report details.
- `src/data/devices.json`: 59-device catalog, including A18 Pro and M1 through M6, merged with the supplied alternate website.
- `src/data/feature-reports.json`: dated, device-specific observations from the previous support pages.
- `src/data/support.json`: Linux support snapshot and device-specific feature groups from the alternate website.
- `src/lib/support.ts`: shared status labels, history lookup, and summaries used by the homepage and device page.
- `src/components/FeaturedDevice.astro`: a monochrome Neo feature summary with links to individual feature notes.
- `src/config.ts`: GitHub, X, Discord, and Omarchy Mac links.
- `src/styles/docs.css`: Starlight branding for light and dark themes.
- `public/brand/`: official master and platform marks.
- `BRAND-GUIDE.md`: the supplied Aurora brand guide.
- `public/`: brand-kit favicons, web manifest, and social preview image.
- `astro.config.mjs`: site metadata, documentation navigation, and integrations.
- `scripts/build.mjs`: production build, local ARM64 search compatibility, and search-index verification.

The supplied brand kit is the source of the logos, palette, and social image. Keep the marks intact and follow its placement rules. The site and documentation focus on Linux. Omarchy Mac has a dedicated homepage section linked to the Aurora repository.

The page base is pure black or white. Logos retain their brand colors; Working and Partial feature pills use restrained green and orange tints. The social preview is a matching vector composition rendered to PNG.

The dependency override for `postcss-selector-parser` selects its patched release while Starlight’s syntax-highlighting dependency still requests the older major.

The device catalog and project policies carry over from the previous site. The catalog links to existing Linux hardware reports; being listed does not establish support. Linux uses the normal A mark; the Tux mark is not used.

The hero Download button jumps to the Omarchy Mac section. Its Download button links to the Omarchy Mac repository. The former download page redirects to this section.

Feature pills use Working, Partial, Not working, and Not recorded from the imported Linux support snapshot. Where only older observations exist, they show Reported. The dated development reports from October 1, 2026 are retained separately and remain available in feature details. Update current states in `support.json` and add dated, model-specific evidence in `feature-reports.json`. Being in the catalog does not imply compatibility.

The support page starts with one row of chip-series tabs, newest first, then device classes. Pro, Max and Ultra are chosen with the model, through compact Size (or iMac Ports) and Chip controls that appear only when they offer a choice; a series with a single Mac skips straight to its results. Hardware-specific groups follow, with green Working and orange Partial pills in both themes. Without JavaScript, the same data is available through nested SoC and device-class disclosure groups. A feature can be linked directly with `/devices/?device=j700&feature=Vulkan`; legacy board hashes are also accepted.

Legacy `/docs/devices/` and `/docs/installation/` URLs redirect to `/devices/` and `/docs/download/`.

## Deployment

The GitHub Pages workflow installs locked dependencies, checks the source, builds `dist/`, and deploys on pushes to `main` or a manual workflow run. Pushing `rework` does not deploy the site. Merging its pull request into `main` triggers deployment.

The canonical URL and `public/CNAME` retain the existing `aurorasilicon.org` domain.

Starlight edit links target `main`.

## Typography, blog, and imagery

Shared typography uses the macOS system face on Macs and self-hosted Geist elsewhere, including buttons and documentation. Blog posts are Markdown in `src/content/blog/`, with title, description, and date frontmatter.

The Omarchy desktop screenshot is the current official Vantablack theme preview, retrieved October 19, 2026 from `https://raw.githubusercontent.com/omacom/omarchy/quattro/themes/vantablack/preview.png`, resized to WebP for the site. Source: [Omarchy](https://github.com/omacom/omarchy), MIT license. It illustrates the Omarchy desktop, rather than a verified Aurora Mac build.

The Neo release article and its media are held in a separate pull request. The blog infrastructure is ready for future posts. The homepage keeps a pure black or white base, with a faint monochrome dot pattern in the hero, restrained button elevation, and rounded screenshot corners with a slight shadow in light mode.

## Alternate website import

Reviewed both `aurora-site-source.zip` and `aurora-site-built.zip` from Downloads. Carried over the latest-device summary, Linux device catalog/status data, profile-specific feature grouping, feature icon concept, and attribution notices. The pure black/white theme, current layout, Linux-only scope, blog, policy text, and Omarchy screenshot remain in place. Source snapshot provenance is recorded in `support.json`; the supplied file did not provide test dates for the current status entries. Original bundles and extracted review copies are retained in Downloads and `.cache/alternate-site/`.

M1/M2 Thunderbolt/USB4, USB-C display output, VRR, Touch ID where fitted, and Secure Enclave statuses include the project owner’s confirmation. These corrections are recorded in `support.json`; other per-device states and earlier dated observations remain separate.

M5 Pro boot, external display, ProMotion, brightness, keyboard and backlight, trackpad, USB-C, HDMI, battery/charging, and fan control use the owner-confirmed Working status where fitted. GPU acceleration, Vulkan, and ray tracing are Partial. These corrections apply to M5 Pro records, not the grouped M5 Max records. Mobile layouts were checked at 320px and 390px, including the horizontally scrolling chip/device rows and two-column model variants.

## Interactive laptop hero

The hero’s live HTML content sits inside `MacBook.astro`, above a flat SVG base. One hinge angle combines the initial opening and scroll-driven closing, so transforms never add together. Perspective is derived from the untransformed lid height and the lid/base width ratio; the fully closing projection is limited to 99.5% of the base width. The perspective origin sits on the hinge, keeping the base and lid centered. Screen contents fade in the last part of closing. Reduced-motion preferences disable movement and keep the screen fully open and visible.

The shared header is sticky glass. Branding is hidden at the top of the homepage and appears after scrolling through the hero. The latest blog entry sits directly below About.

## Licence

Copyright © 2026 The Aurora Silicon Authors, the people listed in `AUTHORS`. All rights reserved. No licence is granted to copy, modify or redistribute this site; see `LICENSE`, which also lists the third-party material that keeps its own licence.
