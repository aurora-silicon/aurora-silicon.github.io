---
title: SSH keys in the Secure Enclave
description: OpenSSH security-key provider with keys inside the Secure Enclave.
sidebar:
  label: SSH keys in the enclave
---

`aurora-sep-sk` creates `ecdsa-sk` keys inside the Secure Enclave and signs there; the private key never touches the disk. It talks to the enclave directly, without the [security key daemon](/docs/userland/security-key/).

Installed by default on Fedora and ALARM, and on NixOS through the Secure Enclave module.

## Use it

```sh
sudo usermod -aG sep-key "$USER"    # then log out and back in
ssh-keygen -t ecdsa-sk -w /usr/lib64/libaurora-sep-sk.so
```

On ALARM the library is `/usr/lib/libaurora-sep-sk.so`. Set `SecurityKeyProvider` in `~/.ssh/config` or `SSH_SK_PROVIDER` in your environment so `ssh` uses it.

The `AURORA_SEP_SK_POLICY` variable picks what each signature needs. `any` means any enrolled finger, `current-set` means the key stops working when your enrolled fingers change.

## Limits

- No resident keys, and the signature counter is always 0.
- A key only works on the Mac and the install that made it. Keep another key on your servers.

Want the same key in browsers too? Use [aurora-fido](/docs/userland/security-key/) instead.

## Source

[aurora-silicon/aurora-sep-userspace](https://github.com/aurora-silicon/aurora-sep-userspace), `docs/ssh-sk.md`.
