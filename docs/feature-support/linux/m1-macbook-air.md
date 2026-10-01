---
title: "MacBook Air · M1 — Linux evidence"
---

# MacBook Air · M1

[Aurora Linux evidence](overview.md) · [M1 catalog](../m1.md)

!!! info "Aurora Linux evidence — 1 October 2026"

    These assessments describe Linux code and Linux hardware reports. Windows results are recorded separately in the generation catalog. A published change or successful build does not demonstrate a complete working system.

Adapted from [discussion #96](https://github.com/aurora-silicon/linux/discussions/96) by [Acelogic](https://github.com/Acelogic), updated 2026-10-01 16:47:00 UTC. The source baseline is [`aurora-wip` at `1d2904fd3301`](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6); separately named branches and open PRs retain their own limits. [Read the evidence legend](overview.md#reading-the-evidence).

**1 board configuration · one shared discussion · Aurora Linux assessment**

**Broad kernel integration is present:** Aurora's working tree includes this product's core platform, NVMe, GPU, DCP display, USB, wireless and audio paths. Board-specific exceptions and Aurora's newer development work are listed below; this assessment is not a blanket pass for every port, firmware version or installation.

**Assessed October 1, 2026.** Baseline: [`aurora-wip` at `1d2904fd3301`](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6). Open PR and `feat/sep` results are identified separately. These statuses come from Aurora's public source and public hardware reports, not another distribution's support table.

## Configurations

| Board | Silicon / SoC | Model / configuration | Year | Aurora assessment |
| :--- | :--- | :--- | :--- | :--- |
| **`J313`** | M1 · `T8103` | MacBook Air | 2020 | 🔵 Broad kernel integration; board reports below |

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
| Built-in microphones | 🔵 AOP audio enabled | Board AOP audio state checked; `CONFIG_SND_SOC_APPLE_AOP_AUDIO=m`. Record actual capture quality and channel behaviour per board. |
| Built-in camera | 🔵 ISP integrated | Enabled ISP node with a matching driver family and `CONFIG_VIDEO_APPLE_ISP=m`. Camera sensor / firmware and runtime capture still need board evidence. |
| Hardware video decode | 🔵 AVD source; 🟠 qualification | AVD nodes and decoder driver are present and `CONFIG_VIDEO_APPLE_AVD=m`. Decoder fixes are open in [#45](https://github.com/aurora-silicon/linux/pull/45); codec / stream coverage and application integration are not a general pass. |
| Video encode / ProRes | ⚪ Unverified | This audit does not establish an integrated, hardware-qualified encode or ProRes pipeline. |
| Neural Engine | 🟠 External-driver research | See [#65](https://github.com/aurora-silicon/linux/pull/65): external driver required. Only explicitly named boards have research results; this is not an in-tree supported inference path. |

## 🔌 I/O and security

| Feature | Aurora status | Evidence / boundary |
| :--- | :--- | :--- |
| USB2 / USB3 host | 🔵 DWC3 integrated | Enabled Apple DWC3 board nodes and configured driver. Port combinations, hubs and role swaps need per-board tests. |
| USB4 / Thunderbolt / USB-C display | 🟠 Driver / development work | Apple Thunderbolt driver source exists, but `CONFIG_USB4` / `CONFIG_USB4_APPLE_SOC` are not selected in the two audited config files. Open [#8](https://github.com/aurora-silicon/linux/pull/8) and [#64](https://github.com/aurora-silicon/linux/pull/64) contain board-specific tunnel / display work; see reports below. |
| Wi-Fi / Bluetooth | 🔵 Wi-Fi board path; 🔵 Bluetooth board path | Broadcom Wi-Fi / Bluetooth drivers configured. Firmware and per-device radio testing are separate. |
| Keyboard / touchpad | 🔵 Built-in input path | SPI HID or dockchannel HID descriptions and Apple input drivers are present. Basic input and trackpad haptic feedback are distinct. |
| Ethernet / SD / PCIe expansion | ⚪ Per-device qualification | PCIe host support is configured. Qualify fitted controllers, adapters and link speeds independently; do not copy support from a sibling board.  |
| SEP / Touch ID | 🟠 Driver / feature-branch work | `CONFIG_APPLE_SEP=m` is present. Current reboot-persistence work is open in [#69](https://github.com/aurora-silicon/linux/pull/69) against `feat/sep`; only named board reports count. Sensor presence is not an enrolment, authentication or lock-screen pass. |

## 🔋 Power and complete-system readiness

| Feature | Aurora status | Evidence / boundary |
| :--- | :--- | :--- |
| Battery / charging / thermals | 🔵 Driver foundation | MACSMC power and thermal / hwmon options are configured. Charge behaviour, runtime and battery-health reporting need a board test. |
| Suspend / resume | 🟠 Board-specific qualification | CPU idle and shutdown drivers do not prove a complete suspend / resume cycle. Only the exact boards and development builds named below have cited runtime results. |
| Installer / complete system | ⚪ Release qualification unverified | This is a public kernel source and evidence audit, not a fresh installation or end-to-end hardware test. Record installer, boot chain, kernel, Mesa and firmware revisions together. |

## 🧪 Aurora hardware reports and development branches

| Board | Feature | State / source | Result and limits |
| :--- | :--- | :--- | :--- |
| J313 | Touch ID after reboot; direct SEP suspend check | 🟢 Reported · 🟠 open [#69](https://github.com/aurora-silicon/linux/pull/69) → `feat/sep` | Enrolment and verification restored; two suspend cycles with a pending direct `/dev/sep-bio` verify recovered. Real lock-screen / fprintd suspend is untested. |
| J313 | Trackpad haptic feedback | 🟢 Reported · 🟠 open [#4](https://github.com/aurora-silicon/linux/pull/4) | SPI haptics tested on this board; host-driven feedback is off by default. |

**PR snapshot:** October 1, 2026. [#69](https://github.com/aurora-silicon/linux/pull/69) supersedes earlier open SEP proposals, but remains separate from the working-tree baseline. “Merged” always names the destination branch; merging into `feat/sep` does not mean merging into `aurora-wip`.

## Pinned Aurora evidence

[Working-tree configuration](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/arch/arm64/configs/asahi.config) · [Arm64 base configuration](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/arch/arm64/configs/defconfig) · [Board build targets](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/arch/arm64/boot/dts/apple/Makefile) · [GPU device matches](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/gpu/drm/asahi/driver.rs) · [DCP driver](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/gpu/drm/apple/dcp.c) · [ISP driver](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/media/platform/apple/isp/isp-drv.c) · [AVD decoder](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/media/platform/apple/avd/avd-drv.c) · [Thunderbolt driver](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/thunderbolt/apple.c) · [Thunderbolt configuration](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/thunderbolt/Kconfig) · [SEP driver](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/drivers/soc/apple/sep.rs)

## Public references

- [The Apple Wiki board identifiers](https://theapplewiki.com/wiki/Models) — public identity cross-reference.
- [M1 series device catalogue](https://github.com/aurora-silicon/aurora-silicon.github.io/blob/1646b0ff5f7068b91710ca5e0498c18fc3cea36e/docs/feature-support/m1.md) — identity source, not a support guarantee.
- [Linux source snapshot](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6) — `aurora-wip` at `1d2904fd3301`.

<details markdown="1">
<summary><strong>Board-specific identity and device-tree references</strong></summary>

- **`J313`:** [Device tree](https://github.com/aurora-silicon/linux/blob/1d2904fd3301c63620f07c81ae79f2486a81a9a6/arch/arm64/boot/dts/apple/t8103-j313.dts).

</details>

## Report a result

Use the [hardware-report template](../../developers/testing.md#hardware-report-template) and post one feature or failure in [discussion #96](https://github.com/aurora-silicon/linux/discussions/96). Include the exact board and revisions; a result on one configuration does not qualify another.

