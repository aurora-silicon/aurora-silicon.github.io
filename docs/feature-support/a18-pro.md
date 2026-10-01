---
title: A18 Pro
---

# A18 Pro

The MacBook Neo uses the A18 Pro (`t8140`) rather than an M-series chip. Its
`j700` board is different enough to track on its own page.

## Primary targets

<div class="split-table" markdown>

| Owner | Machine | Device ID |
| --- | --- | --- |
| RyanTheTide<span class="owner-handle">rttdev</span> | MacBook Neo, A18 Pro, 2026 | `j700` |
| Ace<span class="owner-handle">acelogic_</span> | MacBook Neo, A18 Pro, 2026 | `j700` |

</div>

<p class="targets-note">Hardware on hand, not a support claim. The team owns
other machines besides these.</p>

## Machines

Select a device ID to see its Windows feature detail.

<div class="id-table" markdown>

| Model | Device ID | Chip | SoC ID | Released |
| --- | --- | --- | --- | --- |
| MacBook Neo | `j700` | A18 Pro | `t8140` | 2026 |

</div>

The team has `j700` hardware, and the [MacBook Neo discussion](https://github.com/aurora-silicon/linux/discussions/72) links the Aurora device tree and the work around it.

## Support

!!! warning "Not recorded yet"

    Windows support states for these machines have not been recorded. The
    catalog identifies hardware; it does not claim that Windows works on it.

## Linux bring-up

There is substantial Linux bring-up work for `j700`: platform support, internal storage, keyboard and trackpad, USB, audio and sensors. USB enumeration, CPU-frequency changes and several sensor results have been reported on hardware.

The larger gaps are graphics, wireless, deeper sleep and a complete installation path. Audio still needs speaker tuning and userspace acceptance. The camera series was compile-tested, not tested on the laptop, and Touch ID matching is not working in the cited report. The [MacBook Neo thread](https://github.com/aurora-silicon/linux/discussions/72) keeps the individual results and their limits.

These Linux notes are from **1 October 2026**. They are separate from the Windows
states above. The [support overview](overview.md#reading-a-support-state) explains
how code, hardware results and unfinished work are recorded.

??? info "MacBook Neo"

    Boards: `j700`. [Discussion #72](https://github.com/aurora-silicon/linux/discussions/72) contains the source links and later reports. These notes follow Acelogic's 1 October 2026 assessment.

    **Core platform**

    | Hardware / SoC block | Code | Tests and limits | Sources |
    | :--- | :--- | :--- | :--- |
    | Boot and kernel handoff | Public bootloader work | Full public installation path not established | [m1n1 #2](https://github.com/aurora-silicon/m1n1/pull/2) · [U-Boot #1](https://github.com/aurora-silicon/u-boot/pull/1) |
    | AIC, UART, watchdog, I²C, GPIO, SPMI | Platform prerequisites published | Qualification depends on the individual block | [#10](https://github.com/aurora-silicon/linux/pull/10) (merged) |
    | DART / IOMMU | Implemented | USB DMA reported; later locked-root correction still needs hardware validation | [#34](https://github.com/aurora-silicon/linux/pull/34) (merged) · [locked-root correction](https://github.com/aurora-silicon/linux/commit/1d2904fd3301c63620f07c81ae79f2486a81a9a6) |
    | NVMe / ANS storage | Driver and firmware handoff published | Internal-storage boot reported; reset, durability and suspend qualification are separate | [#21](https://github.com/aurora-silicon/linux/pull/21) (merged) · [#31](https://github.com/aurora-silicon/linux/pull/31) (merged) · [U-Boot #1](https://github.com/aurora-silicon/u-boot/pull/1) |
    | CPU frequency and capacity | Frequency scaling published; capacity change open | Public frequency results; capacity/thermal work still developing | [#22](https://github.com/aurora-silicon/linux/pull/22) (merged) · [#39](https://github.com/aurora-silicon/linux/pull/39) (merged) · [#55](https://github.com/aurora-silicon/linux/pull/55) (open) |
    | CPU idle, deep sleep and perf counters | WFI-only proposal; wider support not established | WFI reported; deeper CPU power-down remains a gap | [#54](https://github.com/aurora-silicon/linux/pull/54) (open) |

    **Display and media**

    | Hardware / SoC block | Code | Tests and limits | Sources |
    | :--- | :--- | :--- | :--- |
    | Framebuffer / DCP / brightness | Boot framebuffer and bootloader DCP handoff | simpledrm reported; full Linux DCP/brightness not established | [#40](https://github.com/aurora-silicon/linux/pull/40) (open) · [m1n1 #2](https://github.com/aurora-silicon/m1n1/pull/2) |
    | GPU acceleration | Complete public T8140 stack not established | Hardware readiness not established in this public assessment | [Public GPU hardware implementations](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/gpu/drm/asahi/hw) |
    | External display / DP Alt Mode | Bootloader groundwork | Complete public Neo Linux display path not established | [m1n1 #2](https://github.com/aurora-silicon/m1n1/pull/2) |
    | MCA / AOP audio; speakers, jack, microphones | Kernel and userspace work published | Final PipeWire/UCM acceptance and speaker tuning remain incomplete | [#13](https://github.com/aurora-silicon/linux/pull/13) (merged) · [#38](https://github.com/aurora-silicon/linux/pull/38) (merged) · [audio documentation](https://github.com/aurora-silicon/asahi-audio/blob/main/README.J700.md) |
    | ISP / webcam | T8140 capture series merged | Reworked kernel series was compile-tested, not hardware-qualified | [#12](https://github.com/aurora-silicon/linux/pull/12) (merged) |
    | Video decode | T8140 AVD variant present | Neo qualification not established; PR #45's extensive results are M1 results | [AVD source](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/media/platform/apple/avd/avd-drv.c) · [#45](https://github.com/aurora-silicon/linux/pull/45) (open) |
    | Video encode / ProRes / Neural Engine | Completed public Neo solution not established | Do not transfer M1/M2 ANE results to T8140 | [#65](https://github.com/aurora-silicon/linux/pull/65) (open) |

    **I/O and security**

    | Hardware / SoC block | Code | Tests and limits | Sources |
    | :--- | :--- | :--- | :--- |
    | USB2 / USB3 / USB-PD | Public port, PHY and DART support | Both connectors enumerate; rear-port SSD reads matched in both orientations; PD reported | [#28](https://github.com/aurora-silicon/linux/pull/28) (merged) · [#30](https://github.com/aurora-silicon/linux/pull/30) (merged) · [#34](https://github.com/aurora-silicon/linux/pull/34) (merged) |
    | PCIe / Wi-Fi / Bluetooth | Public bootloader PCIe groundwork | Complete public Neo Linux radio stack not established | [m1n1 #2](https://github.com/aurora-silicon/m1n1/pull/2) |
    | Keyboard / touchpad | J700 input and board series merged | Preboot keyboard is a separate limitation in U-Boot | [#27](https://github.com/aurora-silicon/linux/pull/27) (merged) · [#30](https://github.com/aurora-silicon/linux/pull/30) (merged) · [U-Boot #1](https://github.com/aurora-silicon/u-boot/pull/1) |
    | SPI / SEP / RNG / Touch ID | SEP branch work is public | SEP services reported; J700 Touch ID matching explicitly not working | [#42](https://github.com/aurora-silicon/linux/pull/42) (open) |

    **Power and system readiness**

    | Hardware / SoC block | Code | Tests and limits | Sources |
    | :--- | :--- | :--- | :--- |
    | SMC / RTC / sensor reporting | Merged | RTC and sensor results reported; some raw sensor labels remain provisional | [#39](https://github.com/aurora-silicon/linux/pull/39) (merged) |
    | Ambient light sensing | AOP / ALS series published | Machine-specific calibration remains necessary | [#11](https://github.com/aurora-silicon/linux/pull/11) (merged) |
    | Battery / charging / thermal policy | Battery work merged; refinements open | Battery transitions and thermal policy still need qualification | [#29](https://github.com/aurora-silicon/linux/pull/29) (merged) · [#43](https://github.com/aurora-silicon/linux/pull/43) (open) · [#53](https://github.com/aurora-silicon/linux/pull/53) (open) |
    | Complete public install and sleep/resume | Incomplete | Full public laptop readiness has not been demonstrated | [m1n1 #2](https://github.com/aurora-silicon/m1n1/pull/2) · [U-Boot #1](https://github.com/aurora-silicon/u-boot/pull/1) |
