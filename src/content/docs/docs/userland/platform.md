---
title: Platform packages
description: The Aurora metapackages and the smaller fixes Aurora carries in its distributions.
---

## Metapackages

On Fedora, `aurora-platform` pulls in the whole Aurora stack, kernel and boot chain included. `aurora-platform-core` is the same set of services without a kernel or boot chain, and replaces the Fedora Asahi Remix metapackage if you are moving over. `aurora-platform-selinux` holds the SELinux rules for these services. SELinux stays enforcing.

`aurora-release`, `aurora-repos` and `aurora-logos` set the release name, the package repository and the artwork.

## Smaller fixes

Aurora carries these until the fixes land upstream:

| Package | Fix |
| --- | --- |
| `aurora-system-fixes` | systemd drop-ins for swap file ordering, parental controls, NetworkManager dispatcher, crash reporter and the reboot watchdog |
| NetworkManager | Wi-Fi stays connected across suspend when wake on network is armed |
| `iwd-aurora` (ALARM) | Enhanced Open (OWE) on the MacBook Neo's Wi-Fi, plus memory safety fixes |
| udisks2 | Apple SSDs show their real size in GNOME About |
| kinfocenter | KDE's About page copes with unknown memory size |
| fastfetch (Fedora) | Recognises the A18 Pro |
| abrt (Fedora) | Startup scan no longer deletes reports still being written |
| docker | No firewalld name conflict when creating the forwarding policy |

## Source

- [aurora-silicon/fedora-aurora](https://github.com/aurora-silicon/fedora-aurora)
- [aurora-silicon/alarm-aurora](https://github.com/aurora-silicon/alarm-aurora)
- [aurora-silicon/nixos-aurora](https://github.com/aurora-silicon/nixos-aurora)
