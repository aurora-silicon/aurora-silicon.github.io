---
title: Power and battery
description: Power profiles, the Power Saver frequency limit, battery reporting and wake for network on Aurora.
---

## Power profiles

The usual Balanced, Power Saver and Performance switch in your desktop works.

- Fedora uses tuned. Performance maps to the `aurora-performance` profile, which keeps the normal CPU governor instead of forcing boost. Check with `tuned-adm active`.
- ALARM and NixOS use power-profiles-daemon.

## Power Saver limit

`aurora-power-budget` caps CPU cluster frequencies while Power Saver is on, so the battery lasts longer. In other modes it does nothing, and thermal limits always win. It does not touch the GPU, Neural Engine or fans.

It is on by default on Fedora and ALARM. On NixOS it is `aurora.powerBudget.enable`, on whenever power-profiles-daemon is.

## Battery

Aurora ships UPower 1.91.5 with a fix for the Mac's battery time estimates (`upower-aurora` on ALARM).

```sh
upower -i $(upower -e | grep battery_)
```

Charge limits use UPower's standard charge threshold settings where the kernel driver supports them. Aurora does not set a charging policy for you.

## Wake for network

Your Mac can wake from sleep on a network magic packet. By default this is on while plugged in and off on battery. To change it, write one word to `/etc/aurora/wake-for-network`:

```sh
echo always | sudo tee /etc/aurora/wake-for-network   # or power-adapter, never
```

On NixOS use `aurora.systemFixes.wakeForNetwork`. A wake-on-LAN setting on a NetworkManager connection takes priority.

## Source

- [aurora-silicon/aurora-platform](https://github.com/aurora-silicon/aurora-platform), `power/`
- [aurora-silicon/upower](https://github.com/aurora-silicon/upower)
