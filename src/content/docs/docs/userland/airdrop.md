---
title: AirDrop
description: AirDrop with iPhones, iPads and Macs over AWDL.
---

`omdrop-awdl` speaks AirDrop over the Wi-Fi chip's AWDL support, the `awdl0` interface.

## Which Macs

Macs with Broadcom BCM4378, BCM4387 or BCM4388 Wi-Fi. Check with:

```sh
lspci -nn | grep 14e4:44
```

The MacBook Neo uses MediaTek Wi-Fi, which has no AWDL.

## Install

| Distribution | Install |
| --- | --- |
| Fedora | `sudo dnf install omdrop-awdl` |
| ALARM | `sudo pacman -S omdrop-awdl` |
| NixOS | `aurora.awdl.enable = true;` |

Nothing runs until you start it.

## Receive files

```sh
sudo /usr/libexec/omdrop/awdl-up                   # bring up awdl0
pkexec /usr/libexec/omdrop/omdrop-discoverable start 600   # visible for 10 minutes
systemctl --user start airdrop-receiver.service    # files land in ~/Downloads
```

On NixOS these tools are on your `PATH`.

## Send files

```sh
send-to-peer --list --names
send-to-peer --mac <MAC> photo.jpg
```

The Apple device must have AirDrop set to "Everyone". Devices set to "Contacts Only" refuse the self-signed identity this tool uses.

## Configuration

Channel settings are in `/etc/omdrop/`. Your identity is a self-signed certificate in `~/.omdrop/keys/`.

## Source

Upstream [netmojo-systems/omdrop-awdl](https://github.com/netmojo-systems/omdrop-awdl). Packaging in [fedora-aurora](https://github.com/aurora-silicon/fedora-aurora/tree/main/packages/omdrop-awdl).
