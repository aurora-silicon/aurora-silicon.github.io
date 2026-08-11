---
title: Aurora Silicon
---

# Aurora Silicon

<p style="text-align:center;margin:0.5rem 0 2rem">
  <img src="assets/brand/aurora-mark-512.png" alt="Aurora Silicon"
       width="180" height="180">
</p>

**Windows on ARM for Apple Silicon.**

Apple Silicon Macs do not expose the hardware interfaces Windows expects — no
GIC, no standard PCIe topology, no conventional storage or display controllers.
Aurora Silicon builds the missing layer: a boot chain, HAL extensions, and the
Windows drivers for Apple's own silicon blocks.

<div class="scoreboard" markdown>
<div class="cell" markdown><div class="n hero">43</div><div class="l">NT drivers in tree</div></div>
<div class="cell" markdown><div class="n hero">1.4</div><div class="l">Vulkan on hardware</div></div>
<div class="cell" markdown><div class="n">11.0</div><div class="l">D3D11 feature level</div></div>
<div class="cell" markdown><div class="n">M2 Pro</div><div class="l">primary target</div></div>
</div>

Windows boots to a desktop from internal storage on a MacBook Pro 14-inch
M2 Pro, with the GPU rendering and presenting frames to the physical console.

## Where things stand

| Capability | State |
| --- | --- |
| Windows boots from internal SSD | <span class="status works">Working</span> |
| Native AIC2 interrupt path (no GIC emulation) | <span class="status works">Working</span> |
| Vulkan on the Apple GPU | <span class="status works">Working</span> — Honeykrisp advertises 1.4.354 |
| Direct3D 11 via DXVK | <span class="status works">Working</span> — feature level 11.0 |
| Presentation to the physical console | <span class="status works">Working</span> — 1,200-frame runs |
| WDDM miniport | <span class="status wip">In progress</span> — builds and tests clean; hardware start next |
| Accelerated DWM desktop | <span class="status wip">Not yet</span> — needs the WDDM present path and a native D3D11 UMD DDI |
| SMP | <span class="status wip">In progress</span> |

!!! warning "Research software"

    This is not production-ready and has had no complete security review. It can
    crash Windows, corrupt data, or leave hardware needing recovery. Use it only
    on systems and installations you can afford to lose, and keep a verified
    recovery path.

## What is being built

**[Drivers](projects/drivers.md)** — 43 Windows driver projects covering
interrupts, DART, PCIe, NVMe, USB4 and DWC3, display and DCP, SMC, SPI/I²C HID,
Wi-Fi and Bluetooth, audio, and more.

**[Graphics](projects/gpu.md)** — a full GPU stack on Windows: a KMDF render
node for AGX, Mesa's Honeykrisp Vulkan driver ported to Windows, and DXVK and
vkd3d-proton on top for Direct3D.

**[Boot chain](projects/windows.md)** — m1n1, Project Mu/UEFI and ACPI tables,
plus `auroradbg` for build, boot, logging and recovery.

**[d3d12agx](projects/d3d12agx/index.md)** — a research effort on Linux: a
native Direct3D 12 driver for AGX with no Vulkan layer, aimed at eventually
replacing the translation chain above.

## Hardware

Development targets **M1 Pro, M2 Pro and M5** systems. The M2 Pro MacBook Pro
14-inch (`j414s`) remains the primary and most validated target. The M5 MacBook
Air (`j813`) is an active preliminary target: m1n1 and UEFI boot, internal
storage is exposed read-only, its GPT is verified, and Windows Setup has
launched. MacBook Neo (8 GB / 256 GB) and M3 Max MacBook Pro are listed for
tracking but have not been tested.

The project hardware pool spans A18 and M1 through M5 systems. See the
[feature-support catalog](platform/support.md) for every Apple Silicon model
family, the machines available in the lab, and the separate validation matrix.

## Getting involved

Development happens on [GitHub](https://github.com/aurora-silicon) and in
[Discord](https://discord.gg/DXmsSSc5aY) — contact `djdev` or `rttdev`.

!!! note "Independent project"

    Aurora Silicon is an independent experimental effort. It is **not** an
    official product of, or supported by, Asahi Linux or the upstream NT-for-ASi
    project, though it builds on public work from both.

    Please do not report bugs caused by these experimental drivers to either
    project unless one of their maintainers explicitly asks for that
    information — report them here.
