---
title: Windows on Apple Silicon
---

# Windows on Apple Silicon

Running Windows on ARM on Apple hardware means supplying everything the platform
normally gets from a vendor: a boot chain, UEFI firmware, ACPI tables describing
hardware Windows has never seen, and NT-side drivers for Apple's own silicon
blocks.

<span class="status partial">Desktop boots</span> A Windows desktop boots from
the internal SSD today. It is software-rendered — there is no GPU driver on the
Windows side yet.

## The boot chain

```
Apple iBoot
    └─ m1n1            bring-up, hypervisor, tracing
        └─ Project Mu  UEFI firmware + ACPI tables
            └─ winload
                └─ Windows on ARM
```

| Component | Repository | Role |
| --- | --- | --- |
| **m1n1** | [aurora-silicon/m1n1](https://github.com/aurora-silicon/m1n1) | Bootloader and experimentation playground. Its hypervisor mode is the primary debugging instrument — it traces guest MMIO access against real hardware |
| **Project Mu** | [aurora-silicon/mu](https://github.com/aurora-silicon/mu) | UEFI implementation for Apple platforms. Produces the firmware environment and ACPI tables Windows requires |
| **Linux** | [aurora-silicon/linux](https://github.com/aurora-silicon/linux) | Asahi kernel tree, used for hardware reference and as the host side of tethered development |

## The interrupt problem

The most substantial NT-side work so far is the interrupt controller.

Apple Silicon does not have a GIC — ARM's standard interrupt controller, which
Windows on ARM assumes. Apple uses **AIC2**, an entirely different design.

Early approaches emulated a GIC in the hypervisor so Windows could use its stock
driver. That works but is slow, fragile, and leaves the guest permanently
mediated. The approach taken here instead is a **native AIC2 HAL extension**: a
Windows HAL extension driver that speaks AIC2 directly, so Windows drives the
real interrupt controller with no emulation layer, no vGIC and no GIC carrier.

WinPE reaches graphical Setup over that purely native path, with hardware device
interrupts delivered and xHCI arbitrating and starting.

## Current focus

- **Peripheral subsystems** — USB, storage and HID confirmation end to end
- **SMP** — multi-processor bring-up; the guest currently runs single-core by
  design while other variables are under test
- **PCIe and DART** — the IOMMU that sits in front of most Apple peripherals
- **Graphics** — today software-rendered. See [d3d12agx](d3d12agx/index.md) for
  the GPU work, though reaching Windows requires a WDDM port that has not been
  started

## Method

This is undocumented hardware, so the working rules are strict:

- **One behavioural variable per boot.** Two changes at once means a result that
  cannot be attributed
- **Measure before hypothesising.** The expensive mistakes in this project have
  all been confident theories acted on without a measurement that could falsify
  them
- **Clean inputs only.** Public documentation, the Asahi and Linux trees,
  Microsoft's public documentation and symbol server, and behaviour observed on
  our own hardware. Leaked material of any kind is excluded — it would
  contaminate the project permanently

## Getting involved

Development happens in [Discord](https://discord.gg/DXmsSSc5aY) and on
[GitHub](https://github.com/aurora-silicon).

!!! warning "Not a supported installation"

    This is active development on hardware that Windows does not officially
    support. Expect it to break, and do not attempt it on a machine whose data
    you care about.
