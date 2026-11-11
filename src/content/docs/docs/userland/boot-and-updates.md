---
title: Boot and updates
description: Boot chain, default OS and updates.
---

## Boot chain

| Package | What it does |
| --- | --- |
| `aura` | Aurora's boot loader. Apple's boot firmware starts it, it draws the logo and loads U-Boot. |
| `uboot-aurora` | U-Boot for Apple Silicon. Starts GRUB or systemd-boot from the EFI partition. |
| `update-m1n1` | Updates aura and its device trees on the EFI partition safely, with a backup. It skips an update when a kernel you kept needs older device trees. |
| `kernel-aurora` / `linux-aurora` | The Aurora kernel (Fedora / ALARM). One kernel for every supported Mac. |

The first stage, installed by the installer from macOS, is never changed by updates.

## Choosing the default OS

Hold the power button at startup for macOS's boot picker. To change the default from Linux, use `aurora-bless`:

```sh
aurora-bless --list-volumes
sudo aurora-bless --set-boot-macos     # boot macOS by default
sudo aurora-bless --next --set-boot 1  # boot volume 1 once
```

## Updates

Nothing updates in the background. Update when you choose to.

### Fedora

```sh
sudo dnf upgrade
```

The Aurora repository is set up by `aurora-repos` in `/etc/yum.repos.d/aurora.repo` and signed with the key in `/etc/pki/rpm-gpg/RPM-GPG-KEY-aurora`.

### Aurora ALARM

```sh
sudo pacman -Syu
```

The `[aurora]` repository sits above `[core]` in `/etc/pacman.conf`. Packages are signed, and `aurora-keyring` provides the key. If you edited a config file that an Aurora package replaces, `aurora-keep-config` puts your version back and saves the new default as `.pacnew`.

### Aurora NixOS

```sh
sudo aurora-update
```

Your `/etc/nixos/flake.nix` follows the nixos-aurora channel. After changing your configuration, apply it with `sudo nixos-rebuild switch --flake /etc/nixos#aurora`. To add Aurora to an existing NixOS system, import `nixosModules.default` and the overlays as shown in [nixos-aurora's docs](https://github.com/aurora-silicon/nixos-aurora/blob/main/docs/modules.md).

## Source

- [aurora-silicon/aura](https://github.com/aurora-silicon/aura)
- [aurora-silicon/u-boot](https://github.com/aurora-silicon/u-boot)
- [aurora-silicon/aurora-bless](https://github.com/aurora-silicon/aurora-bless)
- [aurora-silicon/linux](https://github.com/aurora-silicon/linux)
