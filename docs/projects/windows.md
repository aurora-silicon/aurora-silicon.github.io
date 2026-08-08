---
title: Boot chain
---

# Boot chain and platform

Windows on ARM expects a PC. It expects a GIC for interrupts, a conventional
PCIe topology, standard storage and display controllers, and firmware that
describes all of it through ACPI.

Apple Silicon provides none of that. Everything below exists to bridge the gap
before Windows has even started.

## The chain

```
Apple iBoot
    └─ m1n1              bring-up, hypervisor, hardware tracing
        └─ Project Mu    UEFI firmware + ACPI tables
            └─ winload
                └─ Windows on ARM64
```

| Component | Repository | Role |
| --- | --- | --- |
| **m1n1** | [aurora-silicon/m1n1](https://github.com/aurora-silicon/m1n1) | Bootloader and experimentation playground. Its hypervisor mode is the primary debugging instrument — it traces guest hardware access against real silicon |
| **Project Mu** | [aurora-silicon/mu](https://github.com/aurora-silicon/mu) | UEFI implementation producing the firmware environment and ACPI tables Windows requires |
| **Linux** | [aurora-silicon/linux](https://github.com/aurora-silicon/linux) | Asahi kernel tree — hardware reference, and the host side of tethered development |
| **auroradbg** | in the main tree | Build, boot, logging, recovery and guest control via the `abg` CLI, including chainload failure recovery and bugcheck detection |

Each machine carries its own launch contract and firmware manifest under
`targets/` — a target definition names the Mu profile, build script, output
paths and required features, and pins firmware artifacts by SHA-256.

## The interrupt problem

The most significant platform work is the interrupt controller.

Apple Silicon has no GIC. It uses **AIC2**, an entirely different design, and
Windows on ARM has no driver for it.

One approach is to emulate a GIC in the hypervisor so Windows can use its stock
driver. That works, but it is slow, fragile, and leaves the guest permanently
mediated by the hypervisor.

The approach taken here is a **native AIC2 HAL extension**: a Windows HAL
extension that speaks AIC2 directly. Windows drives the real interrupt
controller with no emulation, no vGIC and no GIC carrier — hardware interrupts
are delivered natively.

## Booting from internal storage

Windows boots from the internal SSD, which requires Apple's own NVMe/ANS storage
controller to work under Windows — `AppleNvme` in the [driver
tree](drivers.md).

## Current focus

- **SMP** — multi-processor bring-up
- **WDDM** — getting the Windows desktop itself GPU-accelerated, see
  [Graphics](gpu.md)
- **Wireless** — Broadcom Wi-Fi and Bluetooth
- **USB and peripherals** — DWC3, xHCI, Type-C

## Working method

This is undocumented hardware, so the rules are strict and were learned
expensively:

- **One behavioural variable per boot.** Two changes at once produce a result
  attributable to neither
- **Measure before hypothesising.** Ask what single number would falsify the
  idea, then go and get it
- **Logs, not symptoms.** Photos and descriptions help but do not substitute for
  serial, hypervisor and debugger logs
- **Clean inputs only.** Public documentation from Asahi and upstream Linux,
  upstream m1n1 and NT-for-ASi, public Arm/ACPI/UEFI/Microsoft Learn/WDK
  documentation, Microsoft public symbols, and traces from hardware the project
  owns. Leaked source, private Apple documentation and material of uncertain
  provenance are not acceptable inputs

## Getting involved

[GitHub](https://github.com/aurora-silicon) and
[Discord](https://discord.gg/DXmsSSc5aY) — contact `djdev` or `rttdev`.

!!! warning "Not a supported installation"

    Test signing, modified boot policy, private HAL interfaces, direct MMIO and
    early-boot instrumentation materially change the security and failure model
    of the system.

    Do not run this on a machine holding data you cannot lose.
