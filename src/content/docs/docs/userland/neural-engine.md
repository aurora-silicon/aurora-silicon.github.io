---
title: Neural Engine
description: Apple Neural Engine driver and tools.
---

The Aurora kernel has an ANE driver. Two packages use it:

- `omarchy-ane-tools`, with `omarchy-ane-run`, `omarchy-ane-smoke` and `omarchy-ane-firmware-fetch`
- `mil-hwx-compiler`, with `mil-hwxc`, a research compiler that turns MIL programs into ANE programs

No inference runtime yet. Which Macs run models: [device support](/devices/), under Neural Engine.

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

## Compile and run a program

The driver shows the engine as `/dev/accel/accel0`, a DRM compute device. `mil-hwxc` compiles a text MIL program (fp16, static shapes, a small set of ops such as conv, matmul, relu, softmax and layer_norm) for your chip's generation, and `omarchy-ane-run` runs the result:

```sh
mil-hwxc --target H13 --mil add.mil --output build/add   # H13 is M1, H14 is M2, H16 is M4
omarchy-ane-run build/add
```

## Check it works

```sh
omarchy-ane-smoke
```

It runs a short test on the ANE and prints JSON. Exit code 2 means the chip or driver isn't supported yet.

## Source

- [aurora-silicon/omarchy-ane](https://github.com/aurora-silicon/omarchy-ane)
- [aurora-silicon/mil-hwx-compiler](https://github.com/aurora-silicon/mil-hwx-compiler)
