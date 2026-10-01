---
title: Linux Platform Evidence
---

# Linux platform evidence

These research notes summarize the **1 October 2026 Aurora Linux assessment**, with a baseline of [`aurora-wip` at `1d2904fd3301`](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6). They identify public implementation and named hardware reports; they do not establish Windows driver or HAL support.

Use the [product matrices](../feature-support/linux/overview.md) for the full feature-by-feature evidence and the [report template](../developers/testing.md#hardware-report-template) for new results.

## SEP and Touch ID

The [M1 MacBook Air](../feature-support/linux/m1-macbook-air.md), [M1 MacBook Pro](../feature-support/linux/m1-macbook-pro.md) and [M2 MacBook Pro](../feature-support/linux/m2-macbook-pro.md) assessments record board-specific enrollment and matching results. The reboot-persistence work in [PR #69](https://github.com/aurora-silicon/linux/pull/69) is open against `feat/sep` in this snapshot; earlier merges into that branch are not integration into `aurora-wip`.

- J313: enrollment and verification were reported restored; two direct SEP verification/suspend cycles recovered. Real lock-screen/fprintd suspend was not tested.
- J293: enrollment and matching after reboot were reported in the development branch.
- J314S: matching was reported after two separate reboots, with additional bring-up retry limitations. J316S was not tested by that PR.
- J414C: three verification matches out of three were reported after reboot. J414S has a separate experimental report in [PR #49](https://github.com/aurora-silicon/linux/pull/49).
- [J700](../feature-support/linux/a18-macbook-neo.md): SEP services were reported, but Touch ID matching was explicitly not working in the cited assessment.

These internal-sensor results do not qualify external Touch ID keyboards or Windows authentication. The separate [Touch ID research](security/touch-id.md) describes the broader stack and open questions.

## Thunderbolt, displays and resume

[PR #8](https://github.com/aurora-silicon/linux/pull/8) and [PR #64](https://github.com/aurora-silicon/linux/pull/64) contain development reports for named M1/M2 laptops, not a family-wide support result. The M1 MacBook Pro assessment records J293 dock USB/display/resume tests and J314S display/replug/short-suspend tests with exact display modes and limitations.

J416S USB keyboard operation through an OWC Thunderbolt hub is recorded in [merged PR #6](https://github.com/aurora-silicon/linux/pull/6). That result alone does not qualify DisplayPort or PCIe tunnels. The [M2 MacBook Pro assessment](../feature-support/linux/m2-macbook-pro.md) keeps the separate display and dual-dock branches visible.

A framebuffer is not a full display pipeline. The M3 assessments identify missing public GPU device matches and full DCP board paths. The [M3 Ultra assessment](../feature-support/linux/m3-mac-studio.md) records firmware-framebuffer description only; brightness, acceleration and external displays do not follow from that description. The existing [d3d12agx research](gpu/d3d12agx.md) remains separate from board qualification.

## J700 storage, DMA and USB

The [J700 matrix](../feature-support/linux/a18-macbook-neo.md) links public bootloader, NVMe/ANS, port-controller and DART work. Both USB connectors were reported to enumerate, with matching rear-port SSD reads in both orientations. The later locked-root DART correction still needs hardware validation.

Internal-storage boot evidence does not qualify reset behavior, durability or suspend. The bootloader handoff and a complete repeatable installation remain separate milestones.

## Audio, camera and power

J700 audio and userspace work is public, but final PipeWire/UCM acceptance and speaker tuning remain incomplete. Its reworked ISP capture series was compile-tested rather than hardware-qualified. Sensor/RTC and CPU-frequency results are recorded separately from battery-transition, thermal-policy and deeper-sleep qualification.

The [M1 iMac](../feature-support/linux/m1-imac.md) and [M3 iMac](../feature-support/linux/m3-imac.md) assessments preserve missing speaker routes; the M3 iMac also records disabled AOP microphone audio. Source routing is not evidence of safe speaker playback.

## Wireless and remaining qualification

Most audited M1–M3 laptop and iMac board paths are present, with firmware and per-device radio testing still separate. [M2 Mac Pro Bluetooth](../feature-support/linux/m2-mac-pro.md) is unverified; absence of an explicit node does not rule out USB enumeration. [M3 Ultra](../feature-support/linux/m3-mac-studio.md) lacks the Wi-Fi board path in the pinned source. J700's bootloader PCIe groundwork does not establish a complete Linux radio stack.

M4–M6 remain unaudited in this snapshot. Neural Engine experiments on named M1/M2 boards do not qualify M3 or T8140, and external-driver experiments are not a packaged supported inference path.

All findings above retain the scope of the original [Aurora hardware discussions](https://github.com/aurora-silicon/linux/discussions/70). A new hardware result should name its board, operating system, build and public artifact before a support state is changed.

