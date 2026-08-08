---
title: Projects
---

# Projects

Aurora Silicon is one goal — Windows running properly on Apple Silicon — split
across the layers it takes to get there.

## [Boot chain and platform](windows.md)

Getting Windows to start at all: m1n1 for bring-up and hypervisor tracing,
Project Mu for UEFI firmware and ACPI tables, and a native HAL extension so
Windows drives Apple's interrupt controller directly rather than through an
emulated GIC.

<span class="status works">Boots to desktop</span> from internal storage on
M2 Pro.

## [Drivers](drivers.md)

43 Windows driver projects for hardware Windows has never seen: DART, PCIe,
Apple's NVMe controller, USB4 and DWC3, the display coprocessor, SMC, SPI HID,
Broadcom Wi-Fi and Bluetooth, audio, sensors.

Some are working, some are early. Each carries its own README with the
authoritative status.

## [Graphics](gpu.md)

A GPU stack on Windows, built on Mesa's reverse-engineered AGX support: a KMDF
render node, Honeykrisp ported to Windows for Vulkan, and DXVK and vkd3d-proton
above it for Direct3D.

<span class="status works">Vulkan 1.4</span> and
<span class="status works">D3D11</span> run on hardware, with frames presented
to the physical console. The WDDM miniport — the piece that gets the Windows
desktop itself accelerated — is in bring-up.

## [d3d12agx](d3d12agx/index.md) — research

A separate experiment, on Linux: a native Direct3D 12 driver for the Apple GPU
with no Vulkan layer at all. Shader bytecode compiles straight to AGX machine
code.

<span class="status partial">Research</span> It passes more of the Direct3D 12
conformance suite than the Vulkan-based route does on the same GPU, which is
evidence the approach is sound. It has no presentation layer and is not part of
the Windows stack today.

If it matures and is ported to a Windows UMD, it would collapse
`D3D12 → vkd3d → Vulkan → AGX` into `D3D12 → AGX`.

## How the layers stack

```
              Windows on ARM
                    │
   ┌────────────────┼────────────────┐
   ▼                ▼                ▼
 drivers        graphics         boot chain
 43 projects    Vulkan/D3D11     m1n1 · Mu/UEFI · ACPI
                DXVK · vkd3d     AicHal
                    │
                    ▼
              AppleAgxGpu.sys
                    │
                   AGX
```

d3d12agx sits outside this diagram for now — it is Linux-side research aimed at
replacing the `vkd3d → Vulkan` hop later.
