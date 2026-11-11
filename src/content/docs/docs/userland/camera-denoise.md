---
title: Camera denoise
description: aurora-camera-denoise cleans up the built-in camera picture in every app, with an extra stage for low light.
---

`aurora-camera-denoise` is a PipeWire video filter for the built-in FaceTime HD camera. Apps pick the filtered camera by default. The unfiltered one is still there as "FaceTime HD Camera (V4L2)".

On by default on every distribution. It only touches the camera while an app is using it.

## How it works

A temporal filter runs on every frame. When the scene is dark enough, a low-light stage joins in and may drop the frame rate to 15 fps to gather more light.

## Which Macs

Every Mac with a built-in camera gets the temporal filter. Low-light settings are tuned for the MacBook Neo and the 16-inch M4 Pro MacBook Pro so far.

## Configuration

Copy the example and edit it:

```sh
mkdir -p ~/.config/aurora-camera-denoise
cp /usr/share/aurora-camera-denoise/examples/denoise.conf ~/.config/aurora-camera-denoise/
systemctl --user reload aurora-camera-denoise
```

`/etc/aurora-camera-denoise/denoise.conf` works for every user. The main keys, under `[denoise]`:

| Key | Values |
| --- | --- |
| `mode` | `auto`, `on`, `off` |
| `temporal` | `on`, `off` |
| `low-light-frame-rate` | `on` (default), `off` |

On NixOS use `aurora.cameraDenoise.settings`.

## Turn it off

```sh
systemctl --user mask --now aurora-camera-denoise
```

`disable` alone doesn't stick, because a preset turns it back on. On NixOS set `aurora.cameraDenoise.enable = false;`.

## Check it works

```sh
systemctl --user status aurora-camera-denoise
```

Your video app should list two cameras.

## Source

[aurora-silicon/camera-denoise](https://github.com/aurora-silicon/camera-denoise)
