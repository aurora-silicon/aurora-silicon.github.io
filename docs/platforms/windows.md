---
title: Windows
---

# Windows on Apple Silicon

The Windows effort covers Windows on ARM boot integration, UEFI and ACPI,
Windows HAL extensions and device drivers.

## Recorded hardware results

Open the [M1](../feature-support/m1.md) or [M2](../feature-support/m2.md) catalog,
select your device ID and choose **Windows**. Existing records are available for
`j316s` and `j414s`; other machines have no Windows states recorded here. Read
the qualifications on each feature before treating it as usable.

These are experimental bring-up results. They do not certify a complete system,
an installer release, or support on another machine with the same chip.

## Installation and removal

The [installation](../users/installation.md) and [removal](../users/removal.md)
pages remain drafts. This site does not yet publish a validated end-to-end
Windows installation procedure. Ask in the
[Aurora Silicon Discord](https://discord.gg/DXmsSSc5aY) for the current route for
your machine before attempting an installation.

## Development and research

Start with the [developer guide](../developers/getting-started.md). Windows HAL
research is under [HAL Extension](../research/hal-extension/aic1.md).
The [d3d12agx research](../research/gpu/d3d12agx.md) describes a Linux library;
its Direct3D API does not make it a Windows driver or establish Windows graphics
support.
