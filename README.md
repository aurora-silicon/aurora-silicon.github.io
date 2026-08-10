# Aurora Silicon documentation

Source for <https://aurorasilicon.org/>.

Windows on ARM and a native Direct3D 12 driver for Apple Silicon.

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

## Contributing

Corrections are welcome, particularly to any figure that turns out to be wrong
or stale. Every number on the site should be reproducible — if one is not, that
is a bug in the documentation.

Note the evidence conventions in `docs/project/method.md`: measured results and
expectations are labelled differently on purpose, and that distinction should be
preserved in edits.
