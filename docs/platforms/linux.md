---
title: Linux
---

# Linux on Apple Silicon

The Linux effort covers kernel and device-tree work, boot integration and
hardware bring-up. Linux also provides the environment for the
[d3d12agx graphics research](../research/gpu/d3d12agx.md) documented on this site.

## Recorded hardware results

Open the [support catalog](../feature-support/overview.md), select your exact
device ID and choose **Linux**. Linux per-machine feature states have not yet
been published in this catalog, so they display **Not recorded**. This does not
mean the hardware is known to fail; Windows states are not used to fill the gap.

A research result on a chip is not a complete machine support claim. Kernel,
boot firmware and graphics versions matter, as do the board and peripherals.

## Installation and removal

This site does not yet publish a validated Aurora Linux installation procedure
or distribution compatibility list. The shared
[installation](../users/installation.md) and [removal](../users/removal.md)
pages are drafts, and Windows instructions must not be reused for Linux.
Ask in the [Aurora Silicon Discord](https://discord.gg/DXmsSSc5aY) for current
guidance for your device, distribution and build.

Aurora Silicon and Asahi Linux are separate projects. For Asahi's own supported
distributions and installation guidance, use the
[Asahi Linux website](https://asahilinux.org/). Their support statements apply
to their software, not automatically to Aurora builds. Keep reports about
Aurora-derived work within Aurora spaces, as explained in our
[policies](../project/policies-and-guidelines.md).

## Development

Start with the [developer guide](../developers/getting-started.md). Select the
kernel and boot components for your target and record exact revisions when
[testing](../developers/testing.md). Shared hardware findings can help Windows
work, but Linux driver results remain Linux results.
