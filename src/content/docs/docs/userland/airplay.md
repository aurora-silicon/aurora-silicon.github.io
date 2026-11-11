---
title: AirPlay receiver
description: AirPlay 2 audio receiver.
---

shairport-sync with AirPlay 2 and nqptp. The Mac appears as a speaker in the AirPlay menu.

Available on Fedora. ALARM does not package the receiver yet. On NixOS use the stock `services.shairport-sync` module, and Aurora's overlay adds the nqptp idle fix.

## Install and enable

```sh
sudo dnf install shairport-sync
sudo systemctl enable --now nqptp shairport-sync
```

Your firewall must allow nqptp's UDP ports 319 and 320, plus the ports shairport-sync uses for AirPlay 2 (see its upstream documentation).

## Configuration

Settings live in `/etc/shairport-sync.conf`. Aurora adds one setting, `general.airplay_model`, the model identifier advertised to senders. It picks the icon shown in the AirPlay picker. Left unset, the receiver shows as "Shairport Sync".

## What Aurora changes

- nqptp no longer wakes the CPU constantly while idle, which matters on a laptop.
- nqptp runs as an unprivileged dynamic user.
- shairport-sync builds against current FFmpeg.

## Check it works

```sh
shairport-sync -V                  # should report AirPlay2
systemctl status nqptp shairport-sync
```

## Source

Packaging in [fedora-aurora](https://github.com/aurora-silicon/fedora-aurora/tree/main/packages/shairport-sync).
