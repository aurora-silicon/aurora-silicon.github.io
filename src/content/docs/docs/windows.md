---
title: Windows
description: Where Windows on Apple Silicon Macs stands in Aurora today, what works, and where it is going.
---

Aurora began as a Windows on Apple Silicon project, and Linux came later. Today Windows is behind. There is no installer, the Windows drivers are not published yet, and only two Macs have recorded results. We want it to be as well supported as Linux, and this page tracks how far it has come.

## How it works

Windows expects a PC-style firmware, UEFI with ACPI tables. A Mac has neither. Aurora's boot loader starts [Mu](https://github.com/aurora-silicon/mu), a UEFI firmware built on Microsoft's Project Mu, which describes the Mac's hardware to Windows in ACPI and provides just enough storage, display and input drivers to start the Windows boot manager. From there Windows needs its own driver for each piece of Apple hardware.

## What works

Results recorded during bring-up. They apply to the named Mac only.

### MacBook Pro 14-inch, M2 Pro (j414s)

Works:

- UEFI boot and Windows Boot Manager
- all CPU cores, with P/E scheduling, frequency scaling and power modes
- internal SSD and internal display
- keyboard, keyboard backlight and trackpad with gestures
- power button, which locks the screen
- USB 3, including Ethernet adapters with Realtek's arm64 driver
- Wi-Fi and Bluetooth
- battery, battery health and fan control

Partial: the GPU runs Vulkan and DXVK, and a WDDM display driver is in progress.

Not yet: speakers, microphones, camera, headset jack, Thunderbolt / USB4, HDMI, SD card slot, ProMotion and HDR, Touch ID, sleep, and nested virtualization (needed for WSL and Hyper-V).

### MacBook Pro 16-inch, M1 Pro (j316s)

UEFI boot, Windows Boot Manager, all CPU cores, the internal display, keyboard and trackpad work. USB-C works without hotplug or USB 3. Nothing else is recorded yet.

### Other Macs

Mu has a platform package for every Mac from M1 to M5 and the MacBook Neo. Bring-up is under way on the M5 Pro MacBook Pro, the M5 MacBook Air and the M6 Mac mini. No results are recorded for them, so treat every other Mac as untested.

## Trying it

You can't install Windows from an Aurora release yet. Developers can build the Mu firmware on macOS:

```sh
git clone https://github.com/aurora-silicon/mu
cd mu
Tools/setup-build.sh
Tools/mu-build j414s
```

[Docs/BUILDING.md](https://github.com/aurora-silicon/mu/blob/main/Docs/BUILDING.md) covers the options. Ask on [Discord](https://discord.gg/DXmsSSc5aY) before trying it on your own Mac.

## Where it is going

- Windows as an option in the [installer](/docs/userland/installer/), next to the Linux distributions.
- Publishing the Windows drivers.
- A hardware GPU driver for Windows. Our Direct3D 12 driver for the Apple GPU runs as research on Linux today.
- Support records per Mac, kept the same way as the [Linux ones](/docs/hardware/).

## Credits

Mu is a fork of the NT-for-ASi Apple Silicon Project Mu firmware, and its layout follows the WOA Project's work for the Surface Duo. Both are credited in the [Mu repository](https://github.com/aurora-silicon/mu).
