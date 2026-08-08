---
title: Aurora Silicon
---

# Aurora Silicon

Bringing **Windows on ARM** and a **native DirectX 12 driver** to Apple Silicon.

Two efforts run in parallel, and they meet at the same destination — a Mac that
boots Windows and draws with its own GPU:

- **[Windows on Apple Silicon](projects/windows.md)** — the boot chain, firmware
  and drivers needed to run Windows on ARM on Apple hardware. A Windows desktop
  boots from the internal SSD today, software-rendered.
- **[d3d12agx](projects/d3d12agx/index.md)** — a from-scratch Direct3D 12
  user-mode driver for the Apple GPU. DXIL and DXBC shader bytecode compile
  straight to AGX machine code: no Vulkan layer, no SPIR-V, no translation.

## Where things stand

<div class="scoreboard" markdown>
<div class="cell" markdown><div class="n hero">523</div><div class="l">D3D12 tests passing</div></div>
<div class="cell" markdown><div class="n ref">505</div><div class="l">reference score, same GPU</div></div>
<div class="cell" markdown><div class="n">+18</div><div class="l">ahead of reference</div></div>
<div class="cell" markdown><div class="n">557</div><div class="l">tests in suite</div></div>
</div>

The reference is **vkd3d-proton running on Vulkan/Honeykrisp on the same Apple
M2** — a mature, widely-deployed D3D12 implementation. d3d12agx now passes more
of the suite than it does on identical hardware.

That is not a claim that the driver is better overall. It is a measurable
consequence of removing a layer: Direct3D 12 → Vulkan is a lossy mapping, and
some D3D12 behaviour simply cannot be expressed through it. Full method and
caveats are in [Conformance](projects/d3d12agx/conformance.md).

!!! warning "Not usable software yet"

    d3d12agx renders correctly on hardware but has **no presentation layer** —
    no swapchain, nothing displays to a window. Every result is an offscreen
    render compared against expected pixels. It cannot run an application today.

## What is actually proven

| Claim | Evidence |
| --- | --- |
| D3D12 shaders compile and execute on AGX | 523/557 of the vkd3d-proton D3D12 suite, per-test logs retained |
| Vertex, geometry, tessellation, mesh and amplification stages all run | Dedicated hardware acceptance suites, pixel-exact against CPU reference |
| No Vulkan or SPIR-V anywhere in the path | DXIL/DXBC → NIR → AGX, in-tree, [architecture](projects/d3d12agx/architecture.md) |
| Windows desktop boots on Apple hardware | Boots from internal SSD, software-rendered |

## Where to start

- New here? [Projects overview](projects/index.md)
- Want the numbers and how they were taken? [Conformance](projects/d3d12agx/conformance.md)
- Want to build it? [Building](developers/building.md)
- Wondering what your Mac supports? [Hardware support](platform/support.md)
- Sceptical? Good — [how we measure](project/method.md) explains what counts as
  proven here and what does not.

## Talk to us

Development happens on [GitHub](https://github.com/aurora-silicon) and in
[Discord](https://discord.gg/DXmsSSc5aY).

!!! note "Relationship to Asahi Linux"

    Aurora Silicon builds on the [Asahi Linux](https://asahilinux.org) kernel,
    the `drm/asahi` GPU driver and the Mesa AGX compiler infrastructure, all of
    which made this work possible. We are a **separate, unaffiliated project**.
    Please direct questions here rather than to Asahi, and do not report our
    bugs to them.
