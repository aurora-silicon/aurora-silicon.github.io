---
title: Keyboard backlight
description: aurora-kbd-light sets the keyboard backlight from the ambient light sensor, the way macOS does.
---

`aurora-kbd-light` turns the keyboard backlight up in the dark and off in bright rooms, with short fades. It is on by default on every distribution.

## Which Macs

MacBooks with a backlit keyboard and an ambient light sensor. On other Macs the service exits quietly.

## How it behaves

- The backlight comes on below 60 lux, goes off above 120 lux and is brightest in near darkness.
- It switches off when the lid closes or every display has been off for a second.
- Your changes win. If you turn the backlight off with the brightness keys or the desktop slider, it stays off until you turn it on again. Any other level you pick holds until the room light changes about fourfold.

## Configuration

`/etc/default/aurora-kbd-light`:

| Variable | Default | Meaning |
| --- | --- | --- |
| `AURORA_KBD_LIGHT_FULL_LUX` | 2 | Full brightness at or below this light level |
| `AURORA_KBD_LIGHT_ON_LUX` | 60 | Turn on below this |
| `AURORA_KBD_LIGHT_OFF_LUX` | 120 | Turn off above this |
| `AURORA_KBD_LIGHT_MIN_PERCENT` | 10 | Lowest automatic level |
| `AURORA_KBD_LIGHT_MAX_PERCENT` | 50 | Highest automatic level |

Restart the service after editing. On NixOS use `aurora.kbdLight.settings` (`fullLux`, `onLux`, `offLux`, `minPercent`, `maxPercent`), or turn it off with `aurora.kbdLight.enable = false;`.

## Check it works

```sh
systemctl status aurora-kbd-light
sudo aurora-kbd-light -v      # run in the foreground and log every change (stop the service first)
```

## Source

[aurora-silicon/kbd-light](https://github.com/aurora-silicon/kbd-light)
