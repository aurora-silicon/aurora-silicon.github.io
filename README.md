# Aurora Silicon website

Source for <https://aurorasilicon.org/>.

## Building locally

```bash
pip install zensical
zensical serve      # live preview at http://localhost:8000
zensical build      # static output in site/
```

Content lives in `docs/`; navigation and theme are configured in
`zensical.toml`.

## Deployment

Pushes to `main` build and publish via GitHub Pages
(`.github/workflows/docs.yml`). No manual step.

The site is currently being redesigned from a clean content structure. Its
previous content is preserved on the `old` branch.
