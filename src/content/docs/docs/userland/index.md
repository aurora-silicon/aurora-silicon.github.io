---
title: Userland and packages
description: The Mac-specific packages in Aurora's distributions.
sidebar:
  label: Overview
  order: 0
---

Three distributions, Fedora Aurora Remix, Aurora ALARM (Arch Linux ARM) and Aurora NixOS, share one set of Mac-specific packages. One page per package.

On means installed and running, Installed means present but off, Available means in the repository.

## Audio

| Component | What it is | Default |
| --- | --- | --- |
| [Speaker protection](/docs/userland/speakerguardd/) | speakerguardd v2, speaker protection in the PipeWire graph | Opt-in preview |
| [Audio stack](/docs/userland/audio/) | PipeWire profiles, ALSA files, plugins, speaker safety daemon | On |
| [AirPlay receiver](/docs/userland/airplay/) | AirPlay 2 audio receiver | Fedora, off |

## Touch ID and the Secure Enclave

| Component | What it is | Default |
| --- | --- | --- |
| [Touch ID](/docs/userland/touch-id/) | Fingerprint unlock for the lock screen, sudo and polkit | On |
| [Touch ID security key](/docs/userland/security-key/) | FIDO2/U2F security key for websites, SSH, PAM and disk unlock | Installed, off |
| [SSH keys in the enclave](/docs/userland/ssh-keys/) | OpenSSH security-key provider | Installed |
| [Disk unlock](/docs/userland/disk-unlock/) | LUKS data volumes unlocked by the Secure Enclave | Opt-in |

## Display, keyboard and camera

| Component | What it is | Default |
| --- | --- | --- |
| [Keyboard backlight](/docs/userland/keyboard-backlight/) | Backlight follows the room light | On |
| [Ambient white point](/docs/userland/ambient-white-point/) | Display colour follows the room light | Off |
| [Brightness and boot splash](/docs/userland/boot-splash/) | One panel brightness from boot loader to login, still logo | On |
| [Camera denoise](/docs/userland/camera-denoise/) | Camera noise filter with a low-light stage | On |

## Graphics, media and apps

| Component | What it is | Default |
| --- | --- | --- |
| [Graphics](/docs/userland/graphics/) | Aurora OpenGL and Borealis Vulkan drivers, also for Flatpak | On |
| [Hardware video decode](/docs/userland/video-decode/) | VA-API on the Apple Video Decoder | Installed, experimental |
| [Hardware video encode](/docs/userland/video-encode/) | H.264, HEVC, ProRes and JPEG encoders through V4L2 | On |
| [x86 apps and Steam](/docs/userland/gaming/) | FEX for x86 programs, native ARM64 Steam | Available |
| [Neural Engine](/docs/userland/neural-engine/) | ANE driver and tools | Available |

## Network and power

| Component | What it is | Default |
| --- | --- | --- |
| [AirDrop](/docs/userland/airdrop/) | AirDrop over AWDL | Available |
| [Power and battery](/docs/userland/power/) | Power profiles, battery reporting, Power Saver limits, wake for network | On |

## System

| Component | What it is | Default |
| --- | --- | --- |
| [Installer](/docs/userland/installer/) | macOS app that installs Aurora |  |
| [First boot and encryption](/docs/userland/first-boot/) | Disk encryption and your account on first start | On |
| [Boot and updates](/docs/userland/boot-and-updates/) | aura, U-Boot, default OS, updates | On |
| [Platform packages](/docs/userland/platform/) | Metapackages and carried fixes | On |

## Not packaged yet

These live in their own repositories and you can build them yourself.

- [aurora-diag](https://github.com/aurora-silicon/aurora-diag) checks sensors, clocks, fans, graphics and services, and writes a report you can attach to a bug. Run `aurora-diag check` or `aurora-diag report -o .`.
- [capture-ns](https://github.com/aurora-silicon/capture-ns) is an experimental microphone noise filter for PipeWire using RNNoise or DeepFilterNet on the CPU.

## Package names

Package names are the same on Fedora and ALARM unless a page says otherwise. On NixOS most components are module options under `aurora.*` from the [nixos-aurora](https://github.com/aurora-silicon/nixos-aurora) flake. The package sources are in [fedora-aurora](https://github.com/aurora-silicon/fedora-aurora), [alarm-aurora](https://github.com/aurora-silicon/alarm-aurora) and [nixos-aurora](https://github.com/aurora-silicon/nixos-aurora).
