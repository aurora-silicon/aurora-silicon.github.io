---
title: Speaker protection (speakerguardd)
description: "speakerguardd v2: speaker protection inside the PipeWire graph, from the Mac's own tuning and calibration."
sidebar:
  label: Speaker protection
---

speakerguardd v2 keeps the built-in speakers within their limits. It runs inside the PipeWire speaker graph, driven by the Mac's own speaker tuning and factory calibration.

:::caution[Preview]
Version 1.0.0-alpha.1. It is opt-in and does not fully match macOS yet. The current protection stack (see [Audio stack](/docs/userland/audio/)) stays the default until you switch.
:::

## What you get

- Apple uses three speaker protection models, and v2 implements all three: one for the 14 and 16-inch MacBook Pro and the M2/M3 and 15-inch MacBook Air, one for the MacBook Neo and 13-inch M4/M5 Air, and one for the 13-inch MacBook Pro and M1 Air. Where the amplifier reports voltage and current, that feeds the model too.
- When nothing plays, the amplifiers and sense streams close. That saves about 1 W at idle on an M2 MacBook Air and 0.4 W on an M1 Pro.
- The first sound after idle is held for a moment and then played in full, so the start of a notification isn't cut off.
- A voicing sink carries your volume and remembers it across restarts. The very first start is at 30%.
- Before it takes the speakers, a self-check proves the wiring using streams of zeros, so you hear nothing.
- Every failure leaves the speakers at the kernel's safe level, and the journal says why.

## Which Macs

PipeWire configurations ship for the Macs whose speakers are recorded as working in [device support](/devices/). Check your Mac there.

A board also has to pass three checks before v2 takes over. Every protection model its tuning uses must be finished, the self-check must pass for that board, kernel and tuning, and the tuning must have been collected from that same Mac. You also need an Aurora kernel that exposes the v2 speaker interface. On an older kernel v2 refuses to run and the current stack keeps the speakers.

## Install and switch

| Distribution | Install |
| --- | --- |
| Fedora | `sudo dnf install speakerguardd-v2 aurora-speaker-upgrade` |
| ALARM | `sudo pacman -S speakerguardd-v2 aurora-speaker-upgrade` |
| NixOS | `aurora.speakerguardd.v2.enable = true;` and `aurora.speakerguardd.upgrade.enable = true;` |

Installing does not switch anything. Run the upgrade tool to move your Mac over:

```sh
sudo aurora-speaker-upgrade --check   # dry run, stores and changes nothing
sudo aurora-speaker-upgrade           # explains, asks, then switches
```

The tool finds your Mac's speaker tuning, compiles it, runs the self-check and switches only if that passes. If v2 has not taken the speakers 30 seconds later, it switches back on its own.

It looks for the tuning in this order: what the installer saved, the macOS system volume on the same disk (read-only), Apple's public restore image for your Mac, or a collection file you make in macOS. `sudo aurora-speaker-upgrade guide` explains the macOS route. The tuning is stored in `/var/lib/aurora-speaker-upgrade/bundle`, readable only by root, and is never sent anywhere.

Other commands:

```sh
aurora-speaker-upgrade status
sudo aurora-speaker-upgrade run --no-switch   # collect and store only
sudo aurora-speaker-upgrade --revert          # back to the current stack
```

## Check it works

```sh
/usr/libexec/speakerguardd-v2/speakerguardd-gate explain      # which stack has the speakers, and why
/usr/libexec/speakerguardd-v2/speakerguardd-provision status  # tuning, parameters and self-check result
systemctl status speakerguardd-v2
systemctl --user status speakerguardd-v2-session
```

On ALARM the helpers are in `/usr/lib/speakerguardd-v2/`. The upgrade tool exits with 0 when done, 1 when it refused, 2 when it should be retried later and 3 on an internal error.

## Configuration

There is one file you may edit, `/etc/speakerguardd/provision.conf`:

```ini
SGV2_SEAT_USER=alice   # the user whose session owns the speakers
SGV2_BUNDLE=/path/to/bundle
```

`/etc/speakerguardd/speakerguardd.conf` is generated at every boot. Don't edit it.

## Troubleshooting

- Read the journal first: `journalctl -b -u speakerguardd-v2-provision -u speakerguardd-v2-selfcheck -u speakerguardd-v2`.
- Tuning collected on another Mac is refused. Collect it again on this one.
- With several users and no sound, provisioning is waiting for the first login. Log in, or set `SGV2_SEAT_USER`.
- To go back, run `sudo aurora-speaker-upgrade --revert`, or on NixOS set `aurora.speakerguardd.v2.enable = false;`.

## Source

[aurora-silicon/speakerguardd](https://github.com/aurora-silicon/speakerguardd/tree/v2), branch `v2`. MIT licensed. The tuning reader is based on aurora-audio-dsp by saku (MIT).
