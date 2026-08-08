---
title: Projects
---

# Projects

Aurora Silicon runs two efforts. They are independent — either could ship
without the other — but they converge on a Mac that boots Windows and renders
with its own GPU rather than a software rasteriser.

## [d3d12agx](d3d12agx/index.md) — DirectX 12 on the Apple GPU

A from-scratch Direct3D 12 **user-mode driver** for Apple's AGX GPU, built on
the Mesa/Asahi substrate. Shader bytecode is compiled directly to AGX machine
code.

<span class="status works">523/557</span> on the vkd3d-proton D3D12 test suite,
against a reference score of 505 on the same hardware.

| | |
| --- | --- |
| Language | C, ~39,000 lines |
| Repository | [aurora-silicon/mesa](https://github.com/aurora-silicon/mesa) (branch `dev`) |
| Licence | MIT, matching Mesa |
| Runs on | Linux on Apple Silicon (M1/M2 families) |
| Blocked on | Presentation — no swapchain yet |

## [Windows on Apple Silicon](windows.md)

The boot chain, firmware and drivers required to run Windows on ARM on Apple
hardware: a tethered `m1n1` bootloader, a Project Mu UEFI implementation, and
NT-side drivers including a native AIC2 interrupt controller HAL extension.

<span class="status partial">Desktop boots</span> from the internal SSD,
software-rendered.

| | |
| --- | --- |
| Repositories | [m1n1](https://github.com/aurora-silicon/m1n1), [mu](https://github.com/aurora-silicon/mu), [linux](https://github.com/aurora-silicon/linux) |
| Status | Boots to desktop; peripheral subsystems in progress |
| Blocked on | SMP, GPU acceleration, peripheral bring-up |

## How they connect

Windows on ARM needs a display driver to be useful. Today that role is filled by
software rendering, which works but is slow. d3d12agx is the graphics half of
the answer — though reaching Windows means porting it to a WDDM user-mode driver
and pairing it with a kernel-mode driver, which is a separate piece of work not
yet started.

A nearer-term application is Linux: shipping d3d12agx as a PE `d3d12.dll` inside
a Wine or Proton build would let Windows games run on Apple Silicon with two
translation layers removed from the graphics path.

```
today   Proton → vkd3d-proton → Honeykrisp (Vulkan) → AGX
target  Proton → d3d12agx → AGX
```

That path needs a Wine unixlib thunk and a present path. Neither exists yet.
