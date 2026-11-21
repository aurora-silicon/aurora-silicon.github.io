---
title: MacBook Air (M3 and M4)
description: What works on the 15-inch M3 MacBook Air (J615) and the 13-inch M4 MacBook Air (J713) on macOS 27.2 firmware, with the pull requests behind each result.
---

This page covers two Macs that the Aurora team has been bringing up in its lab since
19 November 2026:

| Mac | Device | Chip |
| --- | --- | --- |
| MacBook Air 15-inch, M3, 2024 | J615 | M3 (T8122) |
| MacBook Air 13-inch, M4, 2025 | J713 | M4 (T8132) |

Last updated 21 November 2026. The results come from our own runs on these two
Macs. The same Linux user-path check (desktop, browser, Wi-Fi, file copy, video
decode, JPEG encode, sound cards, sensors, battery, failed services) runs on them
every two hours and on our other test Macs for comparison.

:::caution[Two firmware baselines]
This page describes Linux on the **macOS 27.2** firmware (26B123) with current
aura, U-Boot and kernel trees. The Aurora installer still sets these Macs up on
older firmware (macOS 14.8.3 on the M3 Air, 26.6.2 on the M4 Air), and the
[device page](/devices/) records results for that setup. A result on one
baseline does not carry over to the other. See
[Installing on a MacBook Air](/docs/macbook-air-install/) for what that means
when you install.
:::

## Summary

- **15-inch M3 Air (J615):** desktop, browser, Wi-Fi, Bluetooth, storage,
  internal display with brightness, keyboard, camera, microphones, sensors,
  battery, hardware video decode, video encode and suspend to idle all work.
  The GPU, Thunderbolt, external displays and the Neural Engine do not work yet.
- **13-inch M4 Air (J713):** desktop, browser, Wi-Fi, Bluetooth, storage,
  internal display with brightness, keyboard, trackpad, camera, microphones,
  sensors, Thunderbolt networking, battery and hardware video decode all work,
  and the Neural Engine runs on a test kernel. The GPU, sleep, external displays
  and video encode do not work yet.

Several of these results need pull requests that are still open. They work on our
test kernels and will reach an installed system once those pull requests merge and
ship in a release. The tables below say which. On the M3 Air's current default boot
(the distribution's kernel), the internal display driver, camera and light and lid
sensors are not active yet; the desktop, keyboard, Wi-Fi, storage and video
decode work there.

**Status key:** *Works* = proven on the Mac with the numbers shown. *Partial* = works
with a stated limit. *Not yet* = does not work today. *Open PR* = the result needs a
pull request that has not merged.

## 15-inch M3 MacBook Air (J615)

| Feature | Status | Result | Pull requests |
| --- | --- | --- | --- |
| Boot, all CPU cores, cpufreq | Works | All cores up; performance cores at about 4.05 GHz | [linux#2562](https://github.com/aurora-silicon/linux/pull/2562) (merged) |
| GNOME desktop and Firefox | Works | GNOME on Wayland, Firefox loads a page, 0 failed services in all 25 complete runs since 20 November | |
| Internal display | Works, open PR | 2880x1800 at 60 Hz on the display driver, frame pacing 60.000 Hz, brightness 0 to 500 nits, survives suspend | [linux#2580](https://github.com/aurora-silicon/linux/pull/2580) (draft), [aura#227](https://github.com/aurora-silicon/aura/pull/227) (open) |
| Wi-Fi | Works | 2.4 and 5 GHz; over ssh typically 260 to 275 Mbit/s up and 210 to 245 Mbit/s down (21 November runs) | |
| Bluetooth | Works | Controller powered, scanning finds devices | |
| Internal storage | Works | 1 GiB copy at 1200 to 1330 MB/s, cold read 2130 to 2700 MB/s (21 November runs) | |
| Keyboard | Works, open PR | Keys register in the desktop. On the current distribution kernel the keyboard appears about 20 seconds after boot (fixed by linux#2525). Fixes are open for the Do Not Disturb key, which suspended the Mac, and for Mission Control in GNOME ([linux#2624](https://github.com/aurora-silicon/linux/pull/2624), [fedora-aurora#465](https://github.com/aurora-silicon/fedora-aurora/pull/465)) | [linux#2525](https://github.com/aurora-silicon/linux/pull/2525), [u-boot#67](https://github.com/aurora-silicon/u-boot/pull/67) (merged), [linux#2576](https://github.com/aurora-silicon/linux/pull/2576) (open) |
| Trackpad | Partial | Driver ready and reports the full trackpad (16 touches, pressure, haptic click); not yet tested by hand | [linux#2576](https://github.com/aurora-silicon/linux/pull/2576) (open) |
| Keyboard backlight | Works | Brightness 0 to 255 | |
| USB-C | Partial | Device (gadget) mode works at high speed; host mode with a real device not tested yet | [aura#399](https://github.com/aurora-silicon/aura/pull/399) (open) |
| Hardware video decode | Works, open PR | H.264, HEVC, VP9 and AV1, bit-exact against software decode; 1080p at 370, 625, 429 and 448 frames/s (median of about 25 runs on 21 November) | [linux#2586](https://github.com/aurora-silicon/linux/pull/2586) (open), [avd-fw#8](https://github.com/aurora-silicon/avd-fw/pull/8) (merged) |
| JPEG encode | Works | 1080p at 612 frames/s, output identical to our reference | |
| Hardware scaler | Works, open PR | NV12 and P010 to ARGB in BT.601, 709 and 2020 | [linux#2429](https://github.com/aurora-silicon/linux/pull/2429) (open) |
| Camera | Works, open PR | "FaceTime HD Camera" in PipeWire, 1920x1080 at 30 frames/s | [linux#2570](https://github.com/aurora-silicon/linux/pull/2570), [aura#227](https://github.com/aurora-silicon/aura/pull/227) (open) |
| Microphones | Works, open PR | Default PipeWire source in GNOME | [linux#2569](https://github.com/aurora-silicon/linux/pull/2569), [aura#377](https://github.com/aurora-silicon/aura/pull/377) (open) |
| Light and lid sensors | Works, open PR | Ambient light and lid angle read | [aura#377](https://github.com/aurora-silicon/aura/pull/377) (open) |
| Speakers | Not yet | Speaker sense now reads correctly. Quiet test playback under speakerguardd v2 protection works in the lab (no limiting needed, no amplifier faults); speakers stay locked in an install until v2 is qualified on this Mac | [linux#2589](https://github.com/aurora-silicon/linux/pull/2589) (merged), [speakerguardd#225](https://github.com/aurora-silicon/speakerguardd/pull/225) (merged), [speakerguardd#226](https://github.com/aurora-silicon/speakerguardd/pull/226) (merged) |
| Headphone jack | Partial | Jack detected; playback not tested | |
| Battery and charging | Works | Charge, health, cycles and charge limits | |
| Thermals | Works | 10 minutes of full load on all cores without a fan, throttling as designed | |
| Suspend to idle | Works | 13 of 13 wakes by timer, wake by Wi-Fi packet, suspend from the desktop | [linux#2562](https://github.com/aurora-silicon/linux/pull/2562), [linux#2581](https://github.com/aurora-silicon/linux/pull/2581) (merged) |
| GPU | Not yet | The GPU firmware now starts from Linux, but the GPU does not run work on 27.2 yet; the desktop renders in software | |
| External display | Not yet | The external display processor starts, but no picture yet | [linux#2584](https://github.com/aurora-silicon/linux/pull/2584) (open) |
| Thunderbolt / USB4 | Not yet | The Thunderbolt controllers start on a test kernel; no link tested yet, because the only cable on hand is USB 2 | |
| Video encode | Works, open PR | H.264 and HEVC hardware encode: 1080p at 124 to 155 frames/s and 4K at 39 to 41 frames/s, with picture quality matching the M4 Pro MacBook Pro within 0.03 dB | [linux#2644](https://github.com/aurora-silicon/linux/pull/2644), [aura#420](https://github.com/aurora-silicon/aura/pull/420) (open) |
| Neural Engine | Not yet | | |
| Deep sleep | Not yet | | |

## 13-inch M4 MacBook Air (J713)

| Feature | Status | Result | Pull requests |
| --- | --- | --- | --- |
| Boot, all CPU cores, cpufreq | Works | All 10 cores; 30 minutes of full load at 3.91 GHz (performance) and 2.79 GHz (efficiency) with no throttling | |
| Warm reboots | Works, open PR | Storage comes back on warm reboots (5 of 5 on the newest boot chain). About 1 start in 7 from power-off failed in earlier tests; with aura#401 the Mac recovers from that by itself with one reboot | [aura#305](https://github.com/aurora-silicon/aura/pull/305) (merged), [aura#401](https://github.com/aurora-silicon/aura/pull/401) (open) |
| GNOME desktop and Firefox | Works | GNOME on Wayland, Firefox loads a page, 0 failed services in all 23 complete runs since 20 November | |
| Internal display | Works, open PR | 2560x1600 at 60 Hz on the display driver, frame pacing 60.001 Hz, brightness 0 to 500 nits. Without the PR the desktop runs on a basic framebuffer | [linux#2590](https://github.com/aurora-silicon/linux/pull/2590) (open, on [linux#2541](https://github.com/aurora-silicon/linux/pull/2541), draft), [linux#2578](https://github.com/aurora-silicon/linux/pull/2578) (merged) |
| Wi-Fi | Works | 5 GHz; over ssh typically 245 to 275 Mbit/s up and 170 to 235 Mbit/s down (21 November runs) | |
| Bluetooth | Works | Controller powered, scanning finds devices | |
| Internal storage | Works | 1 GiB copy at 1030 to 1080 MB/s, cold read 2090 to 2500 MB/s (21 November runs) | |
| Keyboard | Works | Keys register in the desktop | |
| Trackpad | Works | Touch, move and click register; two-finger scroll not tested yet | |
| Keyboard backlight | Partial | Brightness control present (0 to 255); not checked by eye | |
| USB-C | Works, open PR | Host mode (USB 2 hub, keyboard and mouse through a monitor's hub); device mode at 280 to 332 Mbit/s | [aura#399](https://github.com/aurora-silicon/aura/pull/399) (open) |
| Thunderbolt / USB4 | Works | Host-to-host networking with an M4 Pro MacBook Pro at about 20 Gbit/s | |
| Hardware video decode | Works, open PR | H.264, HEVC, VP9 and AV1, bit-exact; 1080p at 750, 1500, 545 and 789 frames/s (median of about 22 runs on 21 November) | [linux#1487](https://github.com/aurora-silicon/linux/pull/1487), [linux#1488](https://github.com/aurora-silicon/linux/pull/1488) (merged), [linux#2555](https://github.com/aurora-silicon/linux/pull/2555) (open) |
| JPEG encode | Works | 1080p at 732 frames/s, output identical to our reference | |
| Camera | Works | Front camera, 1080p at 30 frames/s, five frame sizes | [aura#309](https://github.com/aurora-silicon/aura/pull/309), [aura#397](https://github.com/aurora-silicon/aura/pull/397) (merged) |
| Microphones | Partial | Three capture devices record | |
| Sensors | Works | Ambient light, light temperature, lid angle, accelerometer, gyroscope, device motion | |
| Speakers | Not yet | Speakers stay at a safe locked level: the speakerguardd v2 upgrade check refuses to unlock them until every protection type this model needs is supported | [speakerguardd#225](https://github.com/aurora-silicon/speakerguardd/pull/225) (merged) |
| Headphone jack | Partial | Jack detected; playback not tested on 27.2 | |
| Battery and charging | Works | 7.5 W idle drain with the screen off (about 6.5 hours) | |
| Thermals | Works | 30 minutes of full load without a fan, chip at 92 to 94 °C, no throttling | |
| GPU | Not yet | The GPU firmware starts but the driver cannot bring it up on 27.2 yet; the desktop renders in software | |
| Sleep | Not yet | | |
| External display | Not yet | DisplayPort alt mode is negotiated with a USB-C monitor, but the port's DisplayPort path is not switched on yet | |
| Video encode | Not yet | | |
| Neural Engine | Works, open PR | The Neural Engine firmware starts and `/dev/accel/accel0` appears. A test program gives bit-exact results over 1000 runs, and an image classification network gives the expected top result 16 of 16 times at about 0.9 ms per run | [linux#2630](https://github.com/aurora-silicon/linux/pull/2630) (open) |
| Touch ID | Partial | Secure Enclave up; no fingerprint test on 27.2 yet | |

## Known gaps

These are the main pieces still missing on 27.2, roughly in the order we expect to
close them:

1. **Display driver in the default install.** The internal display driver works on
   both Macs but needs [linux#2580](https://github.com/aurora-silicon/linux/pull/2580)
   (M3 Air) and [linux#2590](https://github.com/aurora-silicon/linux/pull/2590)
   (M4 Air). Until then the desktop runs on a basic framebuffer with fixed brightness.
2. **GPU.** Both Macs render the desktop in software on 27.2. Expect a slower desktop
   and no hardware OpenGL or Vulkan.
3. **External displays.** No picture yet on either Mac.
4. **Speakers.** Locked on both Macs until speaker protection (speakerguardd v2)
   is qualified for each model. Headphones and microphones are unaffected.
5. **Sleep on the M4 Air.** Not enabled yet. The M3 Air suspends to idle and wakes.
6. **Video encode and the Neural Engine.** Video encode works on the M3 Air with
   [linux#2644](https://github.com/aurora-silicon/linux/pull/2644) and
   [aura#420](https://github.com/aurora-silicon/aura/pull/420) (open) and does not work
   on the M4 Air yet.
   The Neural Engine works on the M4 Air with
   [linux#2630](https://github.com/aurora-silicon/linux/pull/2630) (open); the M3 Air
   is not done yet.

## Reporting results

If you run Linux on one of these Macs, a report helps: follow
[Support records](/docs/hardware/) and include the kernel version (`uname -r`),
the output of `journalctl -b -k -p err`, and whether you installed with the Aurora
installer or on 27.2 firmware.
