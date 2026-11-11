---
title: Disk unlock with the Secure Enclave
description: LUKS2 volumes unlocked by a key sealed in the Secure Enclave.
sidebar:
  label: Disk unlock
---

`aurora-sep-luks` adds a LUKS2 keyslot sealed by the Secure Enclave. The volume unlocks on its own on this Mac and this install. The passphrase keyslot stays.

:::note[Data volumes only]
Unlocking the root volume this way is not possible yet. Use it for a second partition or an external disk.
:::

## Install

| Distribution | Install |
| --- | --- |
| Fedora | `sudo dnf install aurora-sep-luks` |
| ALARM | `sudo pacman -S aurora-sep-luks` |
| NixOS | `aurora.sepLuks.enable = true;` |

## Enrol a volume

```sh
sudo aurora-sep-cryptenroll /dev/nvme0n1pX   # asks for the existing passphrase
sudo aurora-sep-cryptenroll --status /dev/nvme0n1pX
sudo aurora-sep-cryptenroll --test /dev/nvme0n1pX
```

Add the volume to `/etc/crypttab` with `noauto,x-systemd.automount` so it unlocks when first used. A recovery key is a good idea too: `sudo systemd-cryptenroll --recovery-key /dev/nvme0n1pX`.

To remove the enclave slot, use `--wipe-slot=sep`. The tool will not remove your last passphrase slot.

## When it asks for the passphrase

The sealed key is tied to this Mac's enclave and this Linux install. You get the passphrase prompt instead when:

- the disk moves to another Mac,
- Linux is reinstalled, or the enclave's OS identity changes,
- the Touch ID state is reset with `aurora-xart reset-touchid`,
- `/var/lib/aurora-sep-keybag.bin` or `/var/lib/aurora-sep-refkey.bin` is lost.

## Limits

- It does not check which kernel booted, so it does not protect against someone who can change your boot chain.
- No PIN or Touch ID check at unlock time.

## Source

[aurora-silicon/aurora-sep-userspace](https://github.com/aurora-silicon/aurora-sep-userspace), `docs/luks-sep.md`.
