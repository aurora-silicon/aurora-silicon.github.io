---
title: Graphics
description: Aurora OpenGL and Borealis Vulkan drivers, and Flatpak.
---

Mesa with OpenGL, OpenGL ES and Vulkan on the Apple GPU. The OpenGL driver is Aurora, the Vulkan driver is Borealis. Both are preinstalled.

## Packages

| | Fedora | ALARM |
| --- | --- | --- |
| OpenGL | `mesa-aurora-dri-drivers` | `mesa-aurora` |
| Vulkan | `mesa-aurora-vulkan-drivers` | `vulkan-aurora` |
| OpenCL (Rusticl) | `mesa-aurora-libOpenCL` | `opencl-rusticl-aurora` |
| Software Vulkan | `mesa-aurora-vulkan-lavapipe` | `vulkan-lavapipe-aurora` |

NixOS pins the same Mesa in its overlay.

## Flatpak apps

`aurora-flatpak-gl` installs a Flatpak GL extension built from the same Mesa commit and makes it the default, so Flatpak apps use the Aurora driver instead of the generic one. On NixOS it is `aurora.flatpak.enable`, on by default. Removing it falls back to Flatpak's default driver.

## x86 games

`mesa-aurora-fex-guest` provides x86 and 32-bit x86 builds of the same driver for programs running under [FEX](/docs/userland/gaming/).

## Check it works

```sh
glxinfo -B             # renderer should name the Apple GPU, not llvmpipe
vulkaninfo --summary   # driverInfo should mention Borealis
```

## If an app misbehaves

Try the Zink driver (OpenGL on top of Vulkan) for that one app:

```sh
MESA_LOADER_DRIVER_OVERRIDE=zink GALLIUM_DRIVER=zink app
```

Please report the app and your Mac on the [Mesa repository](https://github.com/aurora-silicon/mesa/issues).

## Source

[aurora-silicon/mesa](https://github.com/aurora-silicon/mesa)
