# Aurora Silicon website

Source for <https://aurorasilicon.org/>. The site covers Windows, Linux and
hardware research on Apple Silicon Macs.

## Building locally

Use Python 3.14, matching CI. In a virtual environment:

```sh
python -m pip install -r requirements.txt
zensical serve      # live preview at http://localhost:8000
zensical build --clean
```

Content lives in `docs/`; navigation and theme are configured in
`zensical.toml`. Use the virtual environment's Python and Zensical executables
if it is not activated. Virtual-environment activation commands differ between
Windows and POSIX shells; the build commands above are the same.

## Validation

```sh
python -m pip install -r requirements-test.txt
python -m playwright install chromium firefox webkit
zensical build --clean
python -m unittest discover -s tests -v
```

On Linux, Playwright may also need system packages; CI uses
`python -m playwright install --with-deps chromium firefox webkit`.
The tests check built internal links and anchors, Windows/Linux state isolation,
unrecorded devices, OS-specific boot features, keyboard opening and closing,
instant navigation, narrow viewports and the JavaScript-disabled fallback.
Browser checks run in Chromium, Firefox and WebKit. Viewport tests are not a
substitute for testing on physical mobile devices or every desktop OS.

## Platform and support content

`docs/platforms/` provides Windows and Linux entry points. Hardware pages keep
their existing URLs under `docs/feature-support/`; research pages keep their
existing OS-specific scope and URLs.

`docs/javascripts/device-support.js` owns the interactive catalog:

- `CATALOG` identifies each machine and its provisional hardware profile.
- `FEATURES` lists shared hardware categories, not shared support states.
- `PLATFORMS` defines each OS label and boot milestones.
- `STATES` is keyed by OS, device ID, then feature name. Do not put records at
  the device-only level or copy a result between OSes or machines.

A record is a state string (`works`, `partial`, `none`) or a `[state, note]` pair.
Omit untested features so they display **Not recorded**. Include an OS version
or distribution, exact build/source and firmware revisions, test date,
limitations and reviewable evidence when adding or changing a result. Until
structured evidence fields are introduced, place those details in the note and
link the evidence in the generation page's Support section. Existing Windows
records are preserved but lack full build/evidence metadata; Linux records are
empty until verified material is approved for publication.

Adding another OS requires its `PLATFORMS` entry, a separate `STATES` map, a
platform guide and navigation entry, and updated tests and explanatory copy.
Do not infer support from the visitor's browser OS. The dialog asks explicitly
and remembers the choice only for the current page session/instant navigation.

## Deployment

Pull requests build and run the same checks as `main`, without deploying.
Pushes to `main` publish via GitHub Pages only after validation passes
(`.github/workflows/docs.yml`). Manual runs deploy only when run against `main`.
A branch or draft PR does not update the live site.

The previous site content is preserved on the `old` branch. See
[MULTIPLATFORM-PLAN.md](MULTIPLATFORM-PLAN.md) for this migration's findings,
decisions and remaining content work.
