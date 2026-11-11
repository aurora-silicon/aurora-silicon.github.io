---
title: Brightness and boot splash
description: Keep the panel brightness the same across the boot loader, Linux and macOS, and show one still logo from power-on to login.
---

## Panel brightness

`aurora-panel-nits` saves your screen brightness to the same NVRAM setting macOS uses. The boot loader, Linux and macOS then all start at the brightness you last picked, in any of them. It is on by default.

It saves 5 seconds after you stop changing brightness, at most once a minute, and at shutdown.

| | |
| --- | --- |
| Package | `aurora-panel-nits` (Fedora, ALARM), `aurora.panelNits.enable` (NixOS, on by default) |
| Service | `aurora-panel-nits.service`, started by udev |
| Config | `/etc/default/aurora-panel-nits` (`AURORA_PANEL_NITS_DEBOUNCE_SEC`, `AURORA_PANEL_NITS_MIN_INTERVAL_SEC`) |
| Commands | `aurora-panel-nits save`, `restore`, `watch` |

To stop it, mask `aurora-panel-nits.service`. The [README](https://github.com/aurora-silicon/aurora-bless/tree/master/aurora-panel-nits) has the full steps.

## Boot splash

`plymouth-theme-aurora` draws the logo in the same place the boot loader drew it, so the screen stays still from power-on until the login screen. If your disk is encrypted, the password prompt appears on the splash. Press Esc to see boot messages.

On NixOS the theme is `boot.plymouth.theme = "aurora";`, the default on desktop images. GRUB stays hidden with a one-second timeout.

On the MacBook Neo the splash stops animating once the initrd finishes.

## Source

- [aurora-silicon/aurora-bless](https://github.com/aurora-silicon/aurora-bless) for `aurora-panel-nits`
- [aurora-silicon/aurora-platform](https://github.com/aurora-silicon/aurora-platform) for the splash
