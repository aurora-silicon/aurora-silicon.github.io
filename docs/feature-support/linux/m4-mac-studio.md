---
title: "Mac Studio · M4 — Linux evidence"
---

# Mac Studio · M4

[Aurora Linux evidence](overview.md) · [M4 catalog](../m4.md)

!!! info "Aurora Linux evidence — 1 October 2026"

    These assessments describe Linux code and Linux hardware reports. Windows results are recorded separately in the generation catalog. A published change or successful build does not demonstrate a complete working system.

Adapted from [discussion #141](https://github.com/aurora-silicon/linux/discussions/141) by [Acelogic](https://github.com/Acelogic), updated 2026-10-01 15:58:13 UTC. The source baseline is [`aurora-wip` at `1d2904fd3301`](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6); separately named branches and open PRs retain their own limits. [Read the evidence legend](overview.md#reading-the-evidence).

**1 board configuration · one shared discussion · public evidence only**

Screen sizes, port configurations and chip variants for this product generation belong in this thread. Use the board ID when reporting a difference.

## Configurations

| Board | Silicon / SoC | Model / configuration | Year | Assessment |
| :--- | :--- | :--- | :--- | :--- |
| **`J575C`** | M4 Max · `T6041` | Mac Studio | 2025 | ⚪ Not audited |

!!! info

    **Board support audits are pending.** “Not audited” does not mean unsupported. The matrix below is shared for convenience; results apply only to boards explicitly named in their evidence. Screen, port, firmware and SoC differences remain visible in the table.

**Evidence snapshot:** October 1, 2026. Related PRs are discovery links, not a whole-product support claim.

## Hardware status

### 🧩 Core platform

| Hardware / SoC block | Public implementation | Hardware evidence |
| :--- | :--- | :--- |
| Boot chain and kernel handoff | ⚪ Not audited | Board-specific report needed |
| AIC, UART and watchdog | ⚪ Not audited | Board-specific report needed |
| I²C, GPIO and SPMI | ⚪ Not audited | Board-specific report needed |
| DART / IOMMU and DMA | ⚪ Not audited | Board-specific report needed |
| NVMe / ANS storage | ⚪ Not audited | Board-specific report needed |
| CPU frequency, idle and performance counters | ⚪ Not audited | Board-specific report needed |

### 🎨 Display and media

| Hardware / SoC block | Public implementation | Hardware evidence |
| :--- | :--- | :--- |
| Framebuffer, DCP and brightness | ⚪ Not audited | Board-specific report needed |
| GPU acceleration and userspace graphics | ⚪ Not audited | Board-specific report needed |
| External displays and hotplug | ⚪ Not audited | Board-specific report needed |
| MCA / AOP audio, speakers and microphones | ⚪ Not audited | Board-specific report needed |
| ISP / camera | ⚪ Not audited | Board-specific report needed |
| Video decode, encode, ProRes and Neural Engine | ⚪ Not audited | Board-specific report needed |

### 🔌 I/O and security

| Hardware / SoC block | Public implementation | Hardware evidence |
| :--- | :--- | :--- |
| USB2 / USB3 / USB-PD | ⚪ Not audited | Board-specific report needed |
| USB4 / Thunderbolt and PCIe, where fitted | ⚪ Not audited | Board-specific report needed |
| Wi-Fi and Bluetooth | ⚪ Not audited | Board-specific report needed |
| Keyboard, touchpad and external input | ⚪ Not audited | Board-specific report needed |
| SPI, SEP, RNG and Touch ID | ⚪ Not audited | Board-specific report needed |

### 🔋 Power and system readiness

| Hardware / SoC block | Public implementation | Hardware evidence |
| :--- | :--- | :--- |
| SMC, RTC and sensors | ⚪ Not audited | Board-specific report needed |
| Battery, charging and thermal policy, where fitted | ⚪ Not audited | Board-specific report needed |
| Suspend, resume and shutdown | ⚪ Not audited | Board-specific report needed |
| Installation and repeatable full-system boot | ⚪ Not audited | Board-specific report needed |

## Public references

- [Linux source snapshot](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6) — `aurora-wip` at `1d2904fd3301`.

<details markdown="1">
<summary><strong>Board-specific identity and device-tree references</strong></summary>

- **`J575C`:** [The Apple Wiki board identifiers](https://theapplewiki.com/wiki/Models) · [Device profile](https://theapplewiki.com/wiki/Mac_Studio_(2025)) — public identity cross-reference.
- **`J575C`:** [The Apple Wiki device profile](https://theapplewiki.com/wiki/Mac_Studio_(2025)) — hardware identity, not Linux support.
- **`J575C`:** Device-tree path not matched in this snapshot.

</details>

## Report a result

Use the [hardware-report template](../../developers/testing.md#hardware-report-template) and post one feature or failure in [discussion #141](https://github.com/aurora-silicon/linux/discussions/141). Include the exact board and revisions; a result on one configuration does not qualify another.

