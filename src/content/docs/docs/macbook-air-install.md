---
title: Installing on a MacBook Air (M3 and M4)
description: How the Aurora installer sets up Linux on the 15-inch M3 MacBook Air (J615) and the 13-inch M4 MacBook Air (J713), what to expect, and how to test a kernel safely.
---

This page covers the 15-inch M3 MacBook Air (J615) and the 13-inch M4 MacBook Air
(J713). For what works on them, see [MacBook Air (M3 and M4)](/docs/macbook-air/).
Last updated 21 November 2026.

:::caution[Not tested by the Aurora team yet]
The Aurora installer lists both Macs, but nobody on the team has run a full install
on either of them yet. The [device page](/devices/) shows this as *Installer
untested*. Installs with the installer's current firmware choice have not reached
a working desktop on either Mac in our tests (see [Known problems](#known-problems)),
so we do not recommend installing on these two Macs yet. If you do, back up first.
:::

## Which firmware you get

Linux on a Mac starts from a small macOS installation (the *stub*) that provides the
firmware for the Mac's coprocessors. The installer picks its version per model:

| Mac | Stub the installer uses | Firmware our current bring-up uses |
| --- | --- | --- |
| 15-inch M3 Air (J615) | macOS 14.8.3 | macOS 27.2 |
| 13-inch M4 Air (J713) | macOS 26.6.2 | macOS 27.2 |

The results on the [MacBook Air page](/docs/macbook-air/) are for 27.2. The installer
does not offer 27.2 for these Macs yet.
[aurora-installer#177](https://github.com/aurora-silicon/aurora-installer/pull/177)
(open) moves both Macs to the 27.2 stub; it still needs the drivers listed on the
MacBook Air page to merge and ship in a release before an install matches our
results. Until then, the [device page](/devices/) records the older setup.

## Before you start

- Back up the Mac. The installer only shrinks the macOS volume and adds partitions
  next to it, but resizing a disk always carries some risk.
- Free space in macOS for Linux, plus about 12 GB (M3 Air) or 23 GB (M4 Air) that the
  installer uses while it prepares the firmware. The installer checks both before it
  changes any disk.
- Plug the Mac into power.
- Know your macOS administrator password. You will need it twice: once in macOS and
  once in Recovery.
- Find the power button: it is the Touch ID key at the top right of the keyboard.

## Install

1. In macOS, open **Aurora Installer** (see [Download](/docs/download/); public
   downloads are not open yet).
2. Choose a distribution (Fedora Aurora Remix, Aurora ALARM or Aurora NixOS) and a
   desktop (GNOME, KDE Plasma or a minimal shell), then how much space Linux gets.
3. Enter your administrator password when asked. The installer resizes macOS,
   downloads the macOS firmware for the stub, and writes Linux next to macOS. This
   takes a while; the download alone is several gigabytes.
4. When the installer says so, save your work and shut the Mac down.
5. With the Mac off, **press and hold the power button** until *Loading startup
   options* appears. Do not press and release it first.
6. Choose **Aurora**. Aurora Installer opens in Recovery. Enter your macOS password
   when it asks. It registers Aurora's boot loader with the Mac's firmware; this can
   take several minutes. (Installs made with an older installer show **Aurora →
   Finish Installation** here instead; sign in with your macOS account.)
7. The Mac restarts into Linux.

## Starting macOS or Linux

Aurora installs next to macOS. To choose at startup, shut down, press and hold the
power button until the startup options appear, then pick **Macintosh HD** or
**Aurora**. Select one and choose *Always Use* to make it the default.

If the Mac shows "macOS needs to be reinstalled" or does not start Aurora: shut it
down, hold the power button until the startup options appear, select **Macintosh
HD** and choose *Always Use*. macOS starts as before. You can then open the installer
in macOS and use **Erase Linux** to remove the Aurora installation. macOS and its data
are not changed by any of this.

## Known problems

- **M3 Air (J615), screen goes blank after the boot splash.** Seen on installs on
  the macOS 14.8 stub, which is what the installer uses today. It does not happen on
  27.2, where the desktop starts on the display driver. If it happens, hold the
  power button to shut down and start macOS as above.
- **M4 Air (J713), stops in the boot loader before Linux.** Seen on an install on
  the macOS 26.6.2 stub, which is what the installer uses today, and on some warm
  reboots on 27.2. The boot loader could not always start the internal storage and
  stopped before Linux.
  [aura#305](https://github.com/aurora-silicon/aura/pull/305) fixes this and has
  merged, but it is not in a tagged aura release yet. A rarer failure when the
  storage starts from power-off (about 1 start in 7 in our tests) is handled by
  [aura#401](https://github.com/aurora-silicon/aura/pull/401), still open. If the Mac
  stops before Linux, hold the power button to shut down and start it again.
- **No GPU acceleration on 27.2.** On 27.2 both Macs render the desktop in software.
  See [Known gaps](/docs/macbook-air/#known-gaps).
- **Speakers are locked.** This is deliberate: the speakers stay off until speaker
  protection is qualified for each model, so they cannot be damaged. Headphones and
  microphones are not affected.

## For developers: testing a kernel safely

These Macs have no serial console that you can reach without extra hardware, so a
kernel that hangs early is hard to debug. Our lab works this way, and it suits any
contributor:

1. **Keep a known-good default.** Install your test kernel as an extra boot entry,
   never as the default. Leave the distribution's kernel in place as the fallback.
2. **Boot the test kernel once.** Use `grub2-reboot` (Fedora) or `grub-reboot`
   (Arch Linux ARM) with the test entry, then reboot. The next reboot after that
   returns to the default entry by itself. This needs `GRUB_DEFAULT=saved` in
   `/etc/default/grub`, which Fedora sets by default. If your system has another
   value, set it and regenerate the GRUB configuration first; otherwise the one-time
   entry is ignored and the default kernel starts.
3. **Make a hang end in a reboot.** Add `panic=10` to the test entry's command line
   so a panic reboots after 10 seconds. If the kernel hangs without panicking, hold
   the power button to shut down; the next start uses the default entry. Do not ship
   `panic=` or debug options in a distribution or image.
4. **Collect the log from the next boot.** If the test boot reached systemd,
   `journalctl -b -1 -k` on the next boot shows its kernel log, as long as the
   journal is persistent (`/var/log/journal` exists).
5. **Restore.** Remove the test entry, its initramfs and its modules when you are
   done; `/boot` on these installs is small.

The device trees are `t8122-j615.dtb` (M3 Air) and `t8132-j713.dtb` (M4 Air). Send
kernel changes as pull requests to
[aurora-silicon/linux](https://github.com/aurora-silicon/linux) and boot loader
changes to [aurora-silicon/aura](https://github.com/aurora-silicon/aura). Say which
Mac and which firmware you tested on, and include the numbers. See
[Getting involved](/docs/contributing/).
