---
title: "Mac Pro · M2 — Linux evidence"
---

# Mac Pro · M2

[Aurora Linux evidence](overview.md) · [M2 catalog](../m2.md)

!!! info "Aurora Linux evidence — 1 October 2026"

    These assessments describe Linux code and Linux hardware reports. Windows results are recorded separately in the generation catalog. A published change or successful build does not demonstrate a complete working system.

Adapted from [discussion #116](https://github.com/aurora-silicon/linux/discussions/116) by [Acelogic](https://github.com/Acelogic), updated 2026-10-01 16:47:17 UTC. The source baseline is [`aurora-wip` at `1d2904fd3301`](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6); separately named branches and open PRs retain their own limits. [Read the evidence legend](overview.md#reading-the-evidence).

**1 board configuration · one shared discussion · Aurora Linux assessment**

**Broad kernel integration is present:** Aurora's working tree includes this product's core platform, NVMe, GPU, DCP display, USB, wireless and audio paths. Board-specific exceptions and Aurora's newer development work are listed below; this assessment is not a blanket pass for every port, firmware version or installation.

**Assessed October 1, 2026.** Baseline: [`aurora-wip` at `1d2904fd3301`](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6). Open PR and `feat/sep` results are identified separately. These statuses come from Aurora's public source and public hardware reports, not another distribution's support table.

## Configurations

| Board | Silicon / SoC | Model / configuration | Year | Aurora assessment |
| :--- | :--- | :--- | :--- | :--- |
| **`J180D`** | M2 Ultra · `T6022` | Mac Pro | 2023 | 🔵 Broad kernel integration |

## 🧩 Core platform

| Feature | Aurora status | Evidence / boundary |
| :--- | :--- | :--- |
| Board description / kernel build target | 🔵 Integrated source | Every board above has a DTS and a Makefile target. Bootloader handoff and a repeatable installer run are separate checks. |
| NVMe / ANS storage | 🔵 Integrated source | Enabled storage nodes in every board tree; `CONFIG_NVME_APPLE=m`. |
| CPU frequency / idle | 🔵 Integrated source | Enabled cluster-frequency nodes; Apple cpufreq, CPU idle and PMU options configured. CPU idle is not whole-system suspend qualification. |
| Interrupts / IOMMU / platform buses | 🔵 Integrated source | Apple AIC, DART, GPIO, I²C, SPI, SPMI and RTKit platform options are configured; board-specific nodes are in the linked DTS sources. |
| SMC / RTC / sensors | 🔵 Integrated source | SMC paths present; MACSMC RTC, input, hwmon and power drivers configured. |

## 🎨 Graphics, audio and media

| Feature | Aurora status | Evidence / boundary |
| :--- | :--- | :--- |
| GPU acceleration | 🔵 Kernel driver integrated | Enabled AGX node and matching driver entry for the listed SoCs; `CONFIG_DRM_ASAHI=m`. Mesa, firmware and application / conformance results must be recorded separately. |
| Display pipeline | 🔵 DCP integrated | Enabled DCP / DCPEXT paths and `CONFIG_DRM_APPLE=m`. Connector routing, refresh modes, brightness and hotplug remain board- and firmware-specific. |
| Speakers / headphone jack | 🔵 Speaker + headphone links | MCA / Mac audio drivers and codecs are configured. Audio routing in source does not establish safe speaker tuning or a playback qualification. |
| Built-in microphones | — | Not fitted as built-in microphones to this desktop product. |
| Built-in camera | — | No built-in camera; a generic SoC ISP node is not a fitted camera. |
| Hardware video decode | 🔵 AVD source; 🟠 qualification | AVD nodes and decoder driver are present and `CONFIG_VIDEO_APPLE_AVD=m`. Decoder fixes are open in [#45](https://github.com/aurora-silicon/linux/pull/45); codec / stream coverage and application integration are not a general pass. |
| Video encode / ProRes | ⚪ Unverified | This audit does not establish an integrated, hardware-qualified encode or ProRes pipeline. |
| Neural Engine | 🟠 External-driver research | See [#65](https://github.com/aurora-silicon/linux/pull/65): external driver required. Board-specific research results are listed below; not an in-tree supported inference path. T8112 is excluded, and T602x nodes are disabled in the proposed change. |

## 🔌 I/O and security

| Feature | Aurora status | Evidence / boundary |
| :--- | :--- | :--- |
| USB2 / USB3 host | 🔵 DWC3 integrated | Enabled Apple DWC3 board nodes and configured driver. Port combinations, hubs and role swaps need per-board tests. |
| USB4 / Thunderbolt / USB-C display | 🟠 Driver / development work | Apple Thunderbolt driver source exists, but `CONFIG_USB4` / `CONFIG_USB4_APPLE_SOC` are not selected in the two audited config files. Open [#8](https://github.com/aurora-silicon/linux/pull/8) and [#64](https://github.com/aurora-silicon/linux/pull/64) contain board-specific tunnel / display work; see reports below. |
| Wi-Fi / Bluetooth | 🔵 Wi-Fi board path; ⚪ Bluetooth path unverified | Wi-Fi PCI node exists. No explicit Bluetooth node was found; a USB-enumerated device cannot be classified as unsupported from that absence alone. |
| Keyboard / touchpad | 🔵 External input drivers | USB HID and Bluetooth drivers are configured; pairing and product-specific external keyboard / mouse tests are not established by the board DTS. |
| Ethernet / SD / PCIe expansion | ⚪ Per-device qualification | PCIe host support is configured. Qualify fitted controllers, adapters and link speeds independently; do not copy support from a sibling board. Mac Pro has no built-in SD slot. |
| SEP / Touch ID | 🟠 Driver / feature-branch work | `CONFIG_APPLE_SEP=m` is present. Current reboot-persistence work is open in [#69](https://github.com/aurora-silicon/linux/pull/69) against `feat/sep`; only named board reports count. External Touch ID keyboards are not qualified by internal laptop sensor reports. |

## 🔋 Power and complete-system readiness

| Feature | Aurora status | Evidence / boundary |
| :--- | :--- | :--- |
| Battery / charging / thermals | 🔵 Thermal / power foundation | MACSMC power and thermal / hwmon options are configured. Desktop power and thermal behaviour need a board test; battery status is not applicable. |
| Suspend / resume | 🟠 Board-specific qualification | CPU idle and shutdown drivers do not prove a complete suspend / resume cycle. Only the exact boards and development builds named below have cited runtime results. |
| Installer / complete system | ⚪ Release qualification unverified | This is a public kernel source and evidence audit, not a fresh installation or end-to-end hardware test. Record installer, boot chain, kernel, Mesa and firmware revisions together. |

## 🧪 Aurora hardware reports and development branches

No board-specific runtime result was established in the public Aurora PR evidence reviewed for this product. The integrated-source entries above still document concrete implementation; they should be upgraded to hardware results when a repeatable report identifies the exact board and software revision.

**PR snapshot:** October 1, 2026. [#69](https://github.com/aurora-silicon/linux/pull/69) supersedes earlier open SEP proposals, but remains separate from the working-tree baseline. “Merged” always names the destination branch; merging into `feat/sep` does not mean merging into `aurora-wip`.

## Pinned Aurora evidence

[Working-tree configuration](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/arch/arm64/configs/asahi.config) · [Arm64 base configuration](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/arch/arm64/configs/defconfig) · [Board build targets](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/arch/arm64/boot/dts/apple/Makefile) · [GPU device matches](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/gpu/drm/asahi/driver.rs) · [DCP driver](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/gpu/drm/apple/dcp.c) · [ISP driver](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/media/platform/apple/isp/isp-drv.c) · [AVD decoder](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/media/platform/apple/avd/avd-drv.c) · [Thunderbolt driver](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/thunderbolt/apple.c) · [Thunderbolt configuration](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/thunderbolt/Kconfig) · [SEP driver](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/soc/apple/sep.rs)

## Public references

- [The Apple Wiki board identifiers](https://theapplewiki.com/wiki/Models) — public identity cross-reference.
- [M2 series device catalogue](https://github.com/aurora-silicon/aurora-silicon.github.io/blob/1646b0ff5f7068b91710ca5e0498c18fc3cea36e/docs/feature-support/m2.md) — identity source, not a support guarantee.
- [Linux source snapshot](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6) — `aurora-wip` at `1d2904fd3301`.

<details markdown="1">
<summary><strong>Board-specific identity and device-tree references</strong></summary>

- **`J180D`:** [Device tree](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/arch/arm64/boot/dts/apple/t6022-j180d.dts).

</details>

## Report a result

Use the [hardware-report template](../../developers/testing.md#hardware-report-template) and post one feature or failure in [discussion #116](https://github.com/aurora-silicon/linux/discussions/116). Include the exact board and revisions; a result on one configuration does not qualify another.

