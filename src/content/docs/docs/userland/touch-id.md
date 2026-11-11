---
title: Touch ID
description: Fingerprint unlock backed by the Secure Enclave.
---

Touch ID works for the lock screen, sudo and polkit. The Secure Enclave stores and matches fingerprints; Linux only gets the result.

Login screens, the text console, `su` and SSH still ask for your password. After a boot you type your password once before Touch ID is accepted, like macOS.

## Which Macs

Apple Silicon Macs with a Touch ID sensor that the Aurora kernel's `apple_sep` driver supports. Macs without a sensor still get the other Secure Enclave features (security keys and disk unlock). The Magic Keyboard with Touch ID is not supported.

## Set up

Touch ID is preinstalled on every distribution. At first boot `aurora-touchid-setup` builds the sensor calibration from your Mac's own system data. Nothing is shipped from us.

Enrol a finger in Settings, under Users, or from a terminal:

```sh
fprintd-enroll -f right-index-finger "$USER"
```

## Packages

| Package | What it does |
| --- | --- |
| `aurora-sep` | Starts the Secure Enclave, builds the sensor calibration and wires Touch ID into PAM |
| `libfprint`, `fprintd` | Aurora builds with a driver for the Secure Enclave sensor (`libfprint-aurora` and `fprintd-aurora` on ALARM) |
| `aurora-touchid-rearm` | After a lockout, typing your password turns Touch ID back on |
| `aurora-xart` | Inspect and reset the enclave's stored Touch ID state, like `xartutil` on macOS |

On Fedora this uses an authselect profile, on ALARM a pacman hook, and on NixOS `fprintAuth` for sudo and polkit.

## Configuration

`/etc/aurora/touchid.conf`:

```ini
require_password_after_boot = yes   # set to no to allow Touch ID straight after boot
```

On NixOS use `aurora.sep.requirePasswordAfterBoot`. Fingerprint sign-in on the GNOME login screen is optional, through `aurora-sep-greeter-fingerprint.service` (NixOS `aurora.sep.greeterFingerprint.enable`).

## Check it works

```sh
aurora-sep status                    # PASS / WARN / FAIL lines for each part
sudo aurora-touchid-setup --check
fprintd-list "$USER"
```

## Troubleshooting

- Reboot after updating `aurora-sep` or the kernel. Don't reload the `apple_sep` module, the enclave hands over only once per boot.
- If Touch ID stops after failed tries, type your password once and it comes back.
- To start over, `sudo aurora-xart reset-touchid` clears the stored state. Reboot and enrol every finger again. Keys sealed before the reset, such as [disk unlock](/docs/userland/disk-unlock/) tokens, stop working, so keep your passphrase.
- Don't change the `apple_sep.os_uuid_*` kernel options on an installed system. Doing so orphans your fingerprints and sealed keys.

## Source

The Secure Enclave tools are in [aurora-silicon/linux](https://github.com/aurora-silicon/linux) under `tools/aurora-sep`, the fingerprint driver in [aurora-sep-userspace](https://github.com/aurora-silicon/aurora-sep-userspace) and the reset tool in [aurora-xart](https://github.com/aurora-silicon/aurora-xart).
