---
title: Installer
description: The Aurora installer is a macOS app that sets up Fedora, Arch Linux ARM or NixOS next to macOS, and copies your Mac's own firmware and calibration.
---

The Aurora installer is a native macOS app (macOS 15 or later). It makes room for Linux next to macOS and installs the distribution you pick. macOS stays and you choose which one to start at boot.

## What you can install

| Distribution | Desktops |
| --- | --- |
| Fedora Aurora Remix | KDE Plasma, GNOME or minimal |
| Aurora ALARM (Arch Linux ARM) | KDE Plasma, GNOME or minimal |
| Aurora NixOS | KDE Plasma, GNOME or minimal |

Check your Mac in [device support](/devices/) first.

## What it copies from your macOS

Some files can't be shipped by us, so the installer reads them from your own macOS while it runs:

- Wi-Fi, Bluetooth and camera firmware
- your Mac's speaker tuning, and on MacBooks the factory speaker calibration, used by [speaker protection](/docs/userland/speakerguardd/)
- on the MacBook Neo, radio and light sensor calibration and Touch ID records

Everything stays on your Mac, in the vendor firmware area of the EFI partition, and Linux reads it at boot. Your serial number is only stored as a hash. If collecting the speaker tuning fails, the install carries on and Linux uses a generic profile for your model.

Already installed without it? The [speaker upgrade tool](/docs/userland/speakerguardd/#install-and-switch) can collect the tuning from Linux.

## Getting it

Builds are on [GitHub releases](https://github.com/aurora-silicon/aurora-installer/releases). The installer is alpha software, and the builds are not signed or notarized yet.

## Source

[aurora-silicon/aurora-installer](https://github.com/aurora-silicon/aurora-installer)
