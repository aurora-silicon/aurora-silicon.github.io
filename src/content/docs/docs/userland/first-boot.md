---
title: First boot and encryption
description: "First start: disk encryption and your account."
---

The first time an Aurora system starts, `aurora-firstboot` sets it up:

1. It encrypts the Linux root partition in place with LUKS2.
2. Plasma Setup or GNOME Initial Setup asks for your language, account and password.
3. When you first sign in with that password, it becomes the disk password too.

Until that first sign-in the disk is protected by a temporary key, so finish setup before you rely on the encryption.

## Text mode

Add `aurora.firstboot=text` to the kernel command line to run setup as a text wizard on the first console instead.

## Logs

```sh
journalctl -t aurora-firstboot
```

## Packages

`aurora-firstboot` on Fedora and ALARM. On NixOS the module is part of the installed system, with `aurora.firstboot.passwordHooks` for custom steps.

## Source

[aurora-silicon/aurora-platform](https://github.com/aurora-silicon/aurora-platform)
