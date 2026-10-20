---
title: Attribution
description: Projects and contributors whose work Aurora Silicon builds on.
---

Aurora Silicon builds on years of Apple Silicon research, firmware development, and graphics work by other projects and contributors.

## Asahi Linux

[Asahi Linux](https://asahilinux.org) made much of the Apple Silicon platform accessible through reverse engineering, hardware documentation, and Linux support. Aurora’s bootloader, kernel, U-Boot, and installer trees began as forks of that work.

- [Asahi Linux on GitHub](https://github.com/AsahiLinux)
- [m1n1](https://github.com/AsahiLinux/m1n1)
- [Hardware documentation](https://asahilinux.org/docs/)

## Mesa

Aurora’s graphics drivers build on [Mesa](https://mesa3d.org), the open source graphics stack.

- [Mesa source](https://gitlab.freedesktop.org/mesa/mesa)

## Omarchy

[Omarchy](https://omarchy.org) is Aurora’s flagship distribution for Apple Silicon. The Omarchy and Aurora teams worked together on the Mac experience.

- [Omacom](https://github.com/omacom)
- [Omarchy Mac](https://github.com/aurora-silicon/omarchy-mac)

## MacBook Neo foundations

Neo bring-up builds on work from these contributors and source lineages:

- **Yureka:** initial T8140 support, DebugUSB, proxy, Linux chainloading, and platform bring-up in [m1n1](https://github.com/yuyuyureka/m1n1).
- **Robert Rusch:** Neo framebuffer, proxy boot, and personalised kernelcache work in [asahi_neo](https://github.com/rusch95/asahi_neo) and [m1n1](https://github.com/rusch95/m1n1).
- **Miyako Yakota:** Neo Linux payload and SMP work in [m1n1](https://github.com/MiyakoYakota/m1n1).
- **Dhinak G:** AEA and WKMS reference work for modern IPSW disk images in [aeota](https://github.com/dhinakg/aeota).
- **rafalh:** the [rust-fatfs](https://github.com/rafalh/rust-fatfs) filesystem crate carried in the m1n1 source lineage.
- **Cody Ho:** SPTM and hypervisor research, including [Apple Silicon reverse-engineering notes](https://github.com/ADevWithAnIdea/apple-silicon-re) and [m1n1 work](https://github.com/AsahiLinux/m1n1/pull/622).

The [MacBook Neo release article](/blog/hello-neo/) includes the bring-up story and individual contributor credits.

## Website icons

Feature and device glyphs use [Lucide](https://lucide.dev). The [ISC and MIT licence notices](/licenses/lucide.txt) accompany the icons.

This list is not exhaustive. Repository licence headers, credits, and commit history remain the authoritative record for code provenance. If a credit is missing, please [let us know](https://discord.gg/DXmsSSc5aY).
