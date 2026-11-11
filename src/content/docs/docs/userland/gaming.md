---
title: x86 apps and Steam
description: Run x86 programs with FEX and play games with Valve's native ARM64 Steam client.
---

## FEX

FEX runs x86 and x86-64 Linux programs on your Mac. Aurora ships its own FEX build (`fex-emu`) with an x86 root filesystem.

The Mac's kernel uses 16K memory pages and many x86 programs expect 4K. Run them in a 4K-page environment with `userpages`:

```sh
userpages 4k FEXBash          # a shell where x86 programs run
userpages --status
FEXGetConfig --tso-emulation-info   # shows whether hardware memory ordering is used
```

## Steam

`aurora-steam-native` starts Valve's native ARM64 Steam client inside a 4K-page environment. The client downloads into `~/.local/share/Steam-ARM64` for each user, nothing from Valve is shipped by us. It includes Aurora Play, a small GTK launcher for your games.

| Distribution | Install |
| --- | --- |
| Fedora | `sudo dnf install steam` |
| ALARM | `sudo pacman -S aurora-steam-native` |
| NixOS | `programs.steam.enable = true;` |

Start it from the app menu or with `steam-native4k`. If it fails, the log is in `~/.local/state/aurora-steam-native4k/console.log`.

4K-page environments need the `user4k=on` kernel option. If `userpages --status` or the Steam launcher says it is off, add it and reboot. On Fedora:

```sh
sudo grubby --update-kernel=ALL --args=user4k=on
```

## Source

- [aurora-silicon/fex](https://github.com/aurora-silicon/fex)
- [aurora-silicon/aurora-steam-native](https://github.com/aurora-silicon/aurora-steam-native)
