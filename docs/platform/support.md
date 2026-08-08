---
title: Hardware Support
---

# Hardware support

Status is conservative on purpose. "Tested" means the work has actually been run
on that machine; nothing is marked supported on the strength of it being the same
chip family as something that works.

| | |
| --- | --- |
| <span class="status works">Tested</span> | Validated on this hardware |
| <span class="status partial">Partial</span> | Boots and runs, with known gaps |
| <span class="status wip">Preliminary</span> | Some testing done, not usable |
| <span class="status none">Unsupported</span> | Not supported today |

## Machines

| Machine | SoC | Codename | Status |
| --- | --- | --- | --- |
| MacBook Pro 14-inch (2023) | M2 Pro (T6020, G14S B1) | `j414s` | <span class="status works">Tested</span> — primary target |
| MacBook Pro 16-inch (2021) | M1 Pro (T6000) | `j316s` | <span class="status partial">Partial</span> — earlier bring-up target |
| M5 Pro systems | M5 Pro | — | <span class="status wip">Preliminary</span> — blocked on an unresolved iBoot issue |
| Everything else | — | — | <span class="status none">Unsupported</span> |

**The M2 Pro is the most validated machine by a wide margin.** It is where the
GPU stack, the boot-from-internal-storage path and most recent driver work were
proven. The M1 Pro carried the earlier interrupt-controller and WinPE work and
remains in use, but is behind.

!!! warning "Support does not generalise across machines"

    Unlike the GPU work, Windows bring-up is highly machine-specific. Device
    trees, ACPI tables, peripheral addresses and firmware profiles differ per
    model, so a working configuration on one Mac says very little about another.

    Each target carries its own launch contract and firmware manifest under
    `targets/`.

## Feature status on the primary target

Measured on `j414s` (MacBook Pro 14-inch M2 Pro) under the m1n1 hypervisor.

| Feature | State |
| --- | --- |
| Boot from internal SSD | <span class="status works">Working</span> |
| Native AIC2 interrupts (no GIC emulation) | <span class="status works">Working</span> |
| Vulkan on the GPU | <span class="status works">Working</span> — 1.4.354 advertised |
| Direct3D 11 via DXVK | <span class="status works">Working</span> — feature level 11.0 |
| Presentation to physical console | <span class="status works">Working</span> |
| USB (DWC3, xHCI) | <span class="status partial">Partial</span> |
| Wi-Fi / Bluetooth | <span class="status wip">In progress</span> |
| WDDM display miniport | <span class="status wip">In progress</span> |
| Accelerated DWM desktop | <span class="status wip">Not yet</span> |
| SMP | <span class="status wip">In progress</span> |

## d3d12agx (Linux)

The [d3d12agx](../projects/d3d12agx/index.md) research driver is a separate
piece of work and runs on Linux, not Windows.

| Chip | GPU | Status |
| --- | --- | --- |
| M2 | G14G | <span class="status works">Tested</span> |
| M1, M1 Pro/Max/Ultra, M2 Pro/Max/Ultra | G13G / G13X / G14X | <span class="status partial">Expected</span> — recognised by the substrate, not run |
| M3 and later | AGX2 | <span class="status none">Unsupported</span> — not yet supported by the Mesa AGX substrate |

## Requirements

Windows bring-up needs a host machine for tethered boot and debugging, an m1n1
build matching the target, Project Mu firmware artifacts for that target, and a
test-signing setup. HAL-extension signing needs certificates that are not
distributed here.

Nothing here is a supported installation path. Expect breakage, and do not use a
machine whose data matters.
