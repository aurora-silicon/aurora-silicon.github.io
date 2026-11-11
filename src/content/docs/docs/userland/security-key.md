---
title: Touch ID security key (aurora-fido)
description: Use your Mac's Secure Enclave and Touch ID as a FIDO2/U2F security key for websites, SSH, sudo and disk unlock.
sidebar:
  label: Touch ID security key
---

aurora-fido makes your Mac look like a plugged-in USB security key, the YubiKey kind. Websites, SSH, `pam_u2f` and `systemd-cryptenroll` use it without any changes. Each sign-in needs your finger on the Touch ID sensor.

## How it keeps keys safe

Every key is made inside the Secure Enclave and never leaves it. The enclave runs the fingerprint match itself and refuses to sign unless it saw a match. The daemon on Linux only holds references to the keys. It never decides that a touch happened, so even root cannot sign in as you without your finger.

Known limits, as the project documents them:

- Root can redirect one touch to a different request than the one you meant.
- A compromised kernel could reuse a matched context.
- The signature counter is a file root can rewind.
- Attestation is self-signed, so a website cannot verify the key is Apple hardware.

## Requirements

- At least one enrolled finger (see [Touch ID](/docs/userland/touch-id/)).
- An Aurora kernel with the Secure Enclave key interface and the `uhid` module.

## Enable

It is installed but switched off.

```sh
sudo aurora-fido enable     # checks the enclave can enforce Touch ID, then starts it
aurora-fido status
sudo aurora-fido disable    # off, keys kept
sudo aurora-fido disable --forget   # off, and delete every key it made
```

On NixOS set `aurora.fido.enable = true;`. If a check fails, `enable` refuses and says why. There is no weaker fallback mode.

## Use it

| Where | How |
| --- | --- |
| Websites | Register a security key or passkey in Firefox or Chromium. Flatpak and Snap browsers need hidraw access. |
| SSH | `ssh-keygen -t ecdsa-sk`. The enclave has no Ed25519, so `ed25519-sk` is not offered. With `-O verify-required`, press Enter at the PIN prompt and touch the sensor. |
| sudo and login | `pam_u2f` with `pamu2fcfg` 1.1.1 or later. |
| Disk unlock | `systemd-cryptenroll --fido2-device=auto` for data volumes. Not for the root volume, because the daemon is not in the initrd. |

There is no PIN yet, so `ssh-keygen -K` (resident keys) does not work.

## Configuration

`/etc/aurora-fido/aurora-fido.conf`. The main setting is `policy` in `[touchid]`, which applies to new keys:

| Policy | Meaning |
| --- | --- |
| `touchid-any` (default) | Any enrolled finger |
| `touchid-current` | The key stops working when your enrolled fingers change |

Other settings are `timeout`, `max_tries`, `attestation` (`self` or `none`) and `max_resident`. State lives in `/var/lib/aurora-fido`.

## Check it works

```sh
aurora-fido status
fido2-token -L                # lists "Aurora Touch ID Security Key"
fido2-token -I /dev/hidrawN   # shows FIDO_2_1 and U2F_V2
```

## Troubleshooting

- Keys made by version 0.1 are refused, so register them again. `sudo aurora-fido status` lists the sites.
- A Touch ID lockout is shared with sudo and the lock screen. Type your password once.
- A wrong finger returns "operation denied", no touch returns a timeout.

## Source

[aurora-silicon/aurora-sep-userspace](https://github.com/aurora-silicon/aurora-sep-userspace), in `fido/` and `docs/fido.md`.
