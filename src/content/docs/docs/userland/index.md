---
title: Userland and packages
description: Everything Aurora adds on top of the kernel, what each piece does, and where to read more.
sidebar:
  label: Overview
  order: 0
---

Aurora ships three distributions for Apple Silicon Macs: Fedora Aurora Remix, Aurora ALARM (Arch Linux ARM) and Aurora NixOS. They share one set of Mac-specific packages. Each page here covers one of them: what it does, which Macs it runs on, how to turn it on, how to check it works and where the source lives.

In the tables, On means installed and running, Installed means present but switched off, and Available means it is in the package repository for you to install. Opt-in pages say so at the top.

## Audio

| Component | What it does | Default |
| --- | --- | --- |
| [Speaker protection](/docs/userland/speakerguardd/) | speakerguardd v2, speaker protection inside the PipeWire graph, driven by your Mac's own tuning | Opt-in preview |
| [Audio stack](/docs/userland/audio/) | DSP profiles, ALSA use-case files, plugins and the current speaker safety daemon | On |
| [AirPlay receiver](/docs/userland/airplay/) | Play to your Mac from an iPhone or another Mac | Fedora, off |

## Touch ID and the Secure Enclave

| Component | What it does | Default |
| --- | --- | --- |
| [Touch ID](/docs/userland/touch-id/) | Fingerprint unlock for the lock screen, sudo and polkit | On |
| [Touch ID security key](/docs/userland/security-key/) | Your Mac as a FIDO2/U2F key for websites, SSH, PAM and disk unlock | Installed, off |
| [SSH keys in the enclave](/docs/userland/ssh-keys/) | An OpenSSH security-key provider that talks to the enclave directly | Installed |
| [Disk unlock](/docs/userland/disk-unlock/) | Unlock LUKS data volumes with a key sealed by the Secure Enclave | Opt-in |

## Display, keyboard and camera

| Component | What it does | Default |
| --- | --- | --- |
| [Keyboard backlight](/docs/userland/keyboard-backlight/) | Backlight follows the room light, like macOS | On |
| [Ambient white point](/docs/userland/ambient-white-point/) | Display colour follows the room light, similar to True Tone | Off |
| [Brightness and boot splash](/docs/userland/boot-splash/) | Same panel brightness in the boot loader, Linux and macOS, and a still logo from power-on to login | On |
| [Camera denoise](/docs/userland/camera-denoise/) | Cleaner built-in camera picture, especially in low light | On |

## Graphics, media and apps

| Component | What it does | Default |
| --- | --- | --- |
| [Graphics](/docs/userland/graphics/) | Aurora OpenGL and Borealis Vulkan drivers, and the same driver for Flatpak apps | On |
| [Hardware video decode](/docs/userland/video-decode/) | VA-API on the Apple Video Decoder for players and Firefox | Installed, experimental |
| [x86 apps and Steam](/docs/userland/gaming/) | FEX for x86 programs and the native ARM64 Steam client | Available |
| [Neural Engine](/docs/userland/neural-engine/) | Tools to run programs on the ANE | Available |

## Network and power

| Component | What it does | Default |
| --- | --- | --- |
| [AirDrop](/docs/userland/airdrop/) | Send and receive files with Apple devices over AWDL | Available |
| [Power and battery](/docs/userland/power/) | Power profiles, battery reporting, Power Saver limits and wake for network | On |

## System

| Component | What it does | Default |
| --- | --- | --- |
| [Installer](/docs/userland/installer/) | The macOS app that installs Aurora, and what it copies from your macOS | |
| [First boot and encryption](/docs/userland/first-boot/) | Encrypts the disk and creates your account on first start | On |
| [Boot and updates](/docs/userland/boot-and-updates/) | aura, U-Boot, choosing the default OS and keeping the system current | On |
| [Platform packages](/docs/userland/platform/) | Metapackages and the smaller fixes Aurora carries | On |

## Not packaged yet

These live in their own repositories and you can build them yourself.

- [aurora-diag](https://github.com/aurora-silicon/aurora-diag) checks sensors, clocks, fans, graphics and services, and writes a report you can attach to a bug. Run `aurora-diag check` or `aurora-diag report -o .`.
- [capture-ns](https://github.com/aurora-silicon/capture-ns) is an experimental microphone noise filter for PipeWire using RNNoise or DeepFilterNet on the CPU.

## Package names

Package names are the same on Fedora and ALARM unless a page says otherwise. On NixOS most components are module options under `aurora.*` from the [nixos-aurora](https://github.com/aurora-silicon/nixos-aurora) flake. The package sources are in [fedora-aurora](https://github.com/aurora-silicon/fedora-aurora), [alarm-aurora](https://github.com/aurora-silicon/alarm-aurora) and [nixos-aurora](https://github.com/aurora-silicon/nixos-aurora).
