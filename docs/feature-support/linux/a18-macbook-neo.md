---
title: "MacBook Neo · A18 — Linux evidence"
---

# MacBook Neo · A18

[Aurora Linux evidence](overview.md) · [A18 Pro catalog](../a18-pro.md)

!!! info "Aurora Linux evidence — 1 October 2026"

    These assessments describe Linux code and Linux hardware reports. Windows results are recorded separately in the generation catalog. A published change or successful build does not demonstrate a complete working system.

Adapted from [discussion #72](https://github.com/aurora-silicon/linux/discussions/72) by [Acelogic](https://github.com/Acelogic), updated 2026-10-01 15:57:21 UTC. The source baseline is [`aurora-wip` at `1d2904fd3301`](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6); separately named branches and open PRs retain their own limits. [Read the evidence legend](overview.md#reading-the-evidence).

| Silicon | Board | Machine | Catalogue year |
| :--- | :--- | :--- | :--- |
| **A18 Pro · `T8140`** | **`J700`** | MacBook Neo | 2026 |

!!! info

    **Public implementation is substantial; complete laptop readiness is not established.** Core platform, storage, input, USB, audio and sensors have public work. Graphics, radios, deeper sleep and a complete public installation path remain major gaps.

**Evidence snapshot:** October 1, 2026. Public development branches and open PRs are included; linked test reports retain their original limits.

## Hardware status

### 🧩 Core platform

| Hardware / SoC block | Public implementation | Hardware evidence / limits | Sources |
| :--- | :--- | :--- | :--- |
| Boot and kernel handoff | 🔵 Public bootloader work | 🟠 Full public installation path not established | [m1n1 #2](https://github.com/aurora-silicon/m1n1/pull/2) · [U-Boot #1](https://github.com/aurora-silicon/u-boot/pull/1) |
| AIC, UART, watchdog, I²C, GPIO, SPMI | 🔵 Platform prerequisites published | Qualification depends on the individual block | [#10](https://github.com/aurora-silicon/linux/pull/10) (merged) |
| DART / IOMMU | 🔵 Implemented | 🟢 USB DMA reported; later locked-root correction still needs hardware validation | [#34](https://github.com/aurora-silicon/linux/pull/34) (merged) · [locked-root correction](https://github.com/aurora-silicon/linux/commit/1d2904fd3301c63620f07c81ae79f2486a81a9a6) |
| NVMe / ANS storage | 🔵 Driver and firmware handoff published | 🟠 Internal-storage boot reported; reset, durability and suspend qualification are separate | [#21](https://github.com/aurora-silicon/linux/pull/21) (merged) · [#31](https://github.com/aurora-silicon/linux/pull/31) (merged) · [U-Boot #1](https://github.com/aurora-silicon/u-boot/pull/1) |
| CPU frequency and capacity | 🔵 Frequency scaling published; capacity change open | 🟢 Public frequency results; capacity/thermal work still developing | [#22](https://github.com/aurora-silicon/linux/pull/22) (merged) · [#39](https://github.com/aurora-silicon/linux/pull/39) (merged) · [#55](https://github.com/aurora-silicon/linux/pull/55) (open) |
| CPU idle, deep sleep and perf counters | 🟠 WFI-only proposal; wider support not established | 🟢 WFI reported; 🔴 deeper CPU power-down remains a gap | [#54](https://github.com/aurora-silicon/linux/pull/54) (open) |

### 🎨 Display and media

| Hardware / SoC block | Public implementation | Hardware evidence / limits | Sources |
| :--- | :--- | :--- | :--- |
| Framebuffer / DCP / brightness | 🟠 Boot framebuffer and bootloader DCP handoff | 🟢 simpledrm reported; full Linux DCP/brightness not established | [#40](https://github.com/aurora-silicon/linux/pull/40) (open) · [m1n1 #2](https://github.com/aurora-silicon/m1n1/pull/2) |
| GPU acceleration | 🟠 Complete public T8140 stack not established | Hardware readiness not established in this public assessment | [Public GPU hardware implementations](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/gpu/drm/asahi/hw) |
| External display / DP Alt Mode | 🟠 Bootloader groundwork | Complete public Neo Linux display path not established | [m1n1 #2](https://github.com/aurora-silicon/m1n1/pull/2) |
| MCA / AOP audio; speakers, jack, microphones | 🔵 Kernel and userspace work published | 🟠 Final PipeWire/UCM acceptance and speaker tuning remain incomplete | [#13](https://github.com/aurora-silicon/linux/pull/13) (merged) · [#38](https://github.com/aurora-silicon/linux/pull/38) (merged) · [audio documentation](https://github.com/aurora-silicon/asahi-audio/blob/main/README.J700.md) |
| ISP / webcam | 🔵 T8140 capture series merged | 🟠 Reworked kernel series was compile-tested, not hardware-qualified | [#12](https://github.com/aurora-silicon/linux/pull/12) (merged) |
| Video decode | 🟠 T8140 AVD variant present | Neo qualification not established; PR #45's extensive results are M1 results | [AVD source](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/media/platform/apple/avd/avd-drv.c) · [#45](https://github.com/aurora-silicon/linux/pull/45) (open) |
| Video encode / ProRes / Neural Engine | 🟠 Completed public Neo solution not established | Do not transfer M1/M2 ANE results to T8140 | [#65](https://github.com/aurora-silicon/linux/pull/65) (open) |

### 🔌 I/O and security

| Hardware / SoC block | Public implementation | Hardware evidence / limits | Sources |
| :--- | :--- | :--- | :--- |
| USB2 / USB3 / USB-PD | 🔵 Public port, PHY and DART support | 🟢 Both connectors enumerate; rear-port SSD reads matched in both orientations; PD reported | [#28](https://github.com/aurora-silicon/linux/pull/28) (merged) · [#30](https://github.com/aurora-silicon/linux/pull/30) (merged) · [#34](https://github.com/aurora-silicon/linux/pull/34) (merged) |
| PCIe / Wi-Fi / Bluetooth | 🟠 Public bootloader PCIe groundwork | Complete public Neo Linux radio stack not established | [m1n1 #2](https://github.com/aurora-silicon/m1n1/pull/2) |
| Keyboard / touchpad | 🔵 J700 input and board series merged | 🟠 Preboot keyboard is a separate limitation in U-Boot | [#27](https://github.com/aurora-silicon/linux/pull/27) (merged) · [#30](https://github.com/aurora-silicon/linux/pull/30) (merged) · [U-Boot #1](https://github.com/aurora-silicon/u-boot/pull/1) |
| SPI / SEP / RNG / Touch ID | 🟠 SEP branch work is public | 🟢 SEP services reported; 🔴 J700 Touch ID matching explicitly not working | [#42](https://github.com/aurora-silicon/linux/pull/42) (open) |

### 🔋 Power and system readiness

| Hardware / SoC block | Public implementation | Hardware evidence / limits | Sources |
| :--- | :--- | :--- | :--- |
| SMC / RTC / sensor reporting | 🔵 Merged | 🟢 RTC and sensor results reported; some raw sensor labels remain provisional | [#39](https://github.com/aurora-silicon/linux/pull/39) (merged) |
| Ambient light sensing | 🔵 AOP / ALS series published | 🟠 Machine-specific calibration remains necessary | [#11](https://github.com/aurora-silicon/linux/pull/11) (merged) |
| Battery / charging / thermal policy | 🔵 Battery work merged; refinements open | 🟠 Battery transitions and thermal policy still need qualification | [#29](https://github.com/aurora-silicon/linux/pull/29) (merged) · [#43](https://github.com/aurora-silicon/linux/pull/43) (open) · [#53](https://github.com/aurora-silicon/linux/pull/53) (open) |
| Complete public install and sleep/resume | 🟠 Incomplete | Full public laptop readiness has not been demonstrated | [m1n1 #2](https://github.com/aurora-silicon/m1n1/pull/2) · [U-Boot #1](https://github.com/aurora-silicon/u-boot/pull/1) |

## Public references

- [The Apple Wiki board identifiers](https://theapplewiki.com/wiki/Models) — public identity cross-reference.
- [A18 Pro device catalogue](https://github.com/aurora-silicon/aurora-silicon.github.io/blob/1646b0ff5f7068b91710ca5e0498c18fc3cea36e/docs/feature-support/a18-pro.md) — identity source, not a support guarantee.
- [Device tree](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/arch/arm64/boot/dts/apple/t8140-j700.dts).
- [Linux source snapshot](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6) — `aurora-wip` at `1d2904fd3301`.

### Related board work

- [#43](https://github.com/aurora-silicon/linux/pull/43) (open) — J700: CPU thermal policy on the thermal framework (power allocator, measured energy model) — v2
- [#42](https://github.com/aurora-silicon/linux/pull/42) (open) — SEP: rebase feat/sep-neo onto aurora-wip and enable it on the J700
- [#40](https://github.com/aurora-silicon/linux/pull/40) (open) — arm64: configs: asahi: enable the T8140 console, boot framebuffer and port controllers
- [#39](https://github.com/aurora-silicon/linux/pull/39) (merged) — arm64: dts: apple: j700: SMC RTC in whole seconds and the full SMC sensor set
- [#38](https://github.com/aurora-silicon/linux/pull/38) (merged) — ASoC: apple: t8140-aop-audio: give the hpai PCM a prepare op
- [#34](https://github.com/aurora-silicon/linux/pull/34) (merged) — arm64: dts: apple: t8140-j700: enable the USB DARTs
- [#33](https://github.com/aurora-silicon/linux/pull/33) (merged) — HID: dockchannel: bound empty GET_REPORT response buffers
- [#32](https://github.com/aurora-silicon/linux/pull/32) (merged) — arm64: configs: enable the J700 SMC thermal policy and T8140 AOP audio
- [#30](https://github.com/aurora-silicon/linux/pull/30) (merged) — arm64: dts: apple: t8140/j700: keyboard, trackpad and USB-C topology (reworked, 5 patches)
- [#29](https://github.com/aurora-silicon/linux/pull/29) (merged) — power: supply: macsmc: J700 battery reporting (reworked, 3 patches)
- [#28](https://github.com/aurora-silicon/linux/pull/28) (merged) — usb: apple: T8140 Type-C PHY and DWC3 for the J700 fixed hub (reworked, 12 patches)
- [#27](https://github.com/aurora-silicon/linux/pull/27) (merged) — HID: apple: J700 DockChannel keyboard and trackpad (reworked, 22 patches)

## Report a result

Use the [hardware-report template](../../developers/testing.md#hardware-report-template) and post one feature or failure in [discussion #72](https://github.com/aurora-silicon/linux/discussions/72). Include the exact board and revisions; a result on one configuration does not qualify another.

