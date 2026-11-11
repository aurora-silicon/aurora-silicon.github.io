---
title: Ambient white point
description: Display colour temperature follows the room light.
---

iio-sensor-proxy, gnome-settings-daemon and KWin with colour light sensor support. Off by default.

## Which Macs

Macs whose light sensor reports colour temperature, such as the M1 Pro and M4 Pro MacBook Pro and the M2 MacBook Air. The MacBook Neo's sensor reports brightness only, so it is not supported there.

## Turn it on

GNOME:

```sh
gsettings set org.gnome.settings-daemon.plugins.color ambient-white-point-enabled true
```

KDE Plasma:

```sh
kwriteconfig6 --notify --file kwinrc --group NightColor --key AmbientWhitePoint true
```

Night Light still works alongside it. Whichever asks for the warmer colour wins.

## Check it works

Read the sensor:

```sh
busctl get-property net.hadess.SensorProxy /net/hadess/SensorProxy \
  net.hadess.SensorProxy ColorTemperature
```

On GNOME, the `org.gnome.SettingsDaemon.Color` service on the session bus reports `Temperature` and `AmbientWhitePointActive`. On KDE, `org.kde.KWin.NightLight` reports `appliedTemperature`.

## Limits

GNOME 50 cannot shift displays that only offer a colour matrix. GNOME 51 and KWin can.

## Packages

Fedora carries patched `iio-sensor-proxy`, `gnome-settings-daemon` and `kwin`. ALARM has `iio-sensor-proxy-aurora`, `gnome-settings-daemon-aurora` and `kwin-aurora`. NixOS applies the same patches in its overlay. See [fedora-aurora](https://github.com/aurora-silicon/fedora-aurora/blob/main/docs/ambient-white-point.md) for the patch set.
