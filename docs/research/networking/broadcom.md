---
title: Broadcom
---

# Broadcom

This section tracks the Broadcom wireless hardware used across the catalog's M1–M4 and A18 Pro machines. Operating-system implementation and board-level testing are separate questions.

## Aurora Linux evidence — 1 October 2026

The [Linux product matrices](../../feature-support/linux/overview.md) record configured Wi-Fi and Bluetooth paths for most audited M1–M3 laptops and iMacs. Firmware availability, radio behavior and per-device testing still require evidence.

- [M2 Mac Pro](../../feature-support/linux/m2-mac-pro.md): the Wi-Fi PCI path exists; Bluetooth is unverified. An absent explicit Bluetooth node does not establish failure for a USB-enumerated device.
- [M3 Ultra Mac Studio](../../feature-support/linux/m3-mac-studio.md): the audited board tree lacks Wi-Fi and Bluetooth nodes; the Wi-Fi integration gap and unverified Bluetooth path remain visible.
- [MacBook Neo](../../feature-support/linux/a18-macbook-neo.md): public bootloader PCIe groundwork does not establish a complete Linux Wi-Fi/Bluetooth stack.
- M4: the current public assessment is pending.

## Windows implementation

The driver research notes are still pending. Existing Windows Wi-Fi/Bluetooth results on [J414S](../../feature-support/m2.md#windows-support) remain specific to that board. Linux code or radio tests do not change Windows support states.
