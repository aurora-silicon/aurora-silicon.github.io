---
title: Building
---

# Building

These instructions build d3d12agx from source on an Apple Silicon Mac running
Asahi Linux.

## Prerequisites

- Apple Silicon Mac (M1 or M2 family) running Asahi Linux
- A kernel whose `drm/asahi` UAPI matches the Mesa version you are building
- Meson, Ninja, and a C compiler
- **DirectX-Headers 1.619.1** installed system-wide

DirectX-Headers is not optional and not vendored: the tests include
`<directx/d3d12.h>` and `<wsl/winadapter.h>` directly, so they must resolve
from the system include path.

## Build the driver

```bash
git clone https://github.com/aurora-silicon/mesa
cd mesa
git checkout dev

meson setup _build \
  -Dvulkan-drivers=asahi \
  -Dgallium-drivers= \
  -Dplatforms=wayland \
  -Dtools=asahi \
  -Dasahi-d3d12=true

ninja -C _build
```

The driver lands at `_build/src/asahi/d3d12/libd3d12agx.so`.

!!! tip "Check the build actually succeeded"

    Capture Ninja's own exit status rather than piping it into another command:

    ```bash
    ninja -C _build > build.log 2>&1; rc=$?
    ```

    Piping into `grep` and reading `$?` reports *grep's* status, which has
    produced a false "build failed" here more than once.

## Verify it runs

The acceptance suites render on real hardware and compare against CPU reference
rasterisation:

```bash
src/asahi/d3d12/tests/run-suites.sh
```

Every suite should pass with nothing skipped. If they do not, stop here — the
conformance suite will produce noise on a broken build.

The shader corpus check is a separate, compile-only proxy:

```bash
src/asahi/d3d12/tests/corpus-passset.sh > now
```

## Layout

```
src/asahi/d3d12/
├── d12_device.c       ID3D12Device, adapter/feature queries, view creation
├── d12_cmd.c          command lists, draws, dispatches, USC/PPP encoding
├── d12_queue.c        submission, fences (DRM syncobj timelines)
├── d12_resource.c     resource creation, ail layout selection
├── d12_descriptor.c   descriptor heaps
├── d12_pipeline.c     PSO compile, prolog/epilog linking
├── d12_root_sig.c     root signature serialise/parse (RTS0)
├── d12_format.c       DXGI ↔ pipe format
├── dxil/              DXIL and DXBC → NIR
└── tests/             acceptance suites, tools, shaders
```

## Notes

`tests/corpus/` is empty in the repository by design. Those shaders are derived
from vkd3d-proton, which is LGPL, so they are regenerated locally rather than
vendored into an MIT tree.

Newer probe shaders are built as NIR by `tests/make_probe.c` and emitted through
Mesa's own `nir_to_dxil`, so they need nothing outside this tree — `dxc` does
not run on the target platform.

Next: [running the conformance suite](testing.md).
