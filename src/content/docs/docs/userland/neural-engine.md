---
title: Neural Engine
description: Tools to run programs on the Apple Neural Engine from Linux.
---

The Aurora kernel has a driver for the Apple Neural Engine (ANE). Two packages let you use it:

- `omarchy-ane-tools`, with `omarchy-ane-run`, `omarchy-ane-smoke` and `omarchy-ane-firmware-fetch`
- `mil-hwx-compiler`, with `mil-hwxc`, a research compiler that turns MIL programs into ANE programs

There is no ready-made inference runtime yet, so this is for developers for now.

## Set up

```sh
sudo dnf install omarchy-ane-tools mil-hwx-compiler   # or pacman -S on ALARM
sudo usermod -aG accel "$USER"                        # log out and back in
```

On NixOS set `aurora.ane.enable = true;` and add `accel` to your user's `extraGroups`.

M2-family Macs need the ANE firmware from Apple, fetched on your own machine:

```sh
sudo omarchy-ane-firmware-fetch   # then reboot
```

## Check it works

```sh
omarchy-ane-smoke
```

It runs a short test on the ANE and prints JSON. Exit code 2 means the chip or driver isn't supported yet.

## Source

- [aurora-silicon/omarchy-ane](https://github.com/aurora-silicon/omarchy-ane)
- [aurora-silicon/mil-hwx-compiler](https://github.com/aurora-silicon/mil-hwx-compiler)
