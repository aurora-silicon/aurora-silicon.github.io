---
title: Broadcom
---

# Broadcom

Research notes on the Broadcom wireless hardware used across M1 to M4 machines
and the A18 Pro.

## Linux bring-up

Most of the assessed M1–M3 laptops and iMacs have Wi-Fi and Bluetooth paths in
the tree. Firmware and testing on each machine are separate work.

The [M2 Mac Pro](https://github.com/aurora-silicon/linux/discussions/116) has a
Wi-Fi path, but Bluetooth still needs checking. The
[M3 Ultra Mac Studio](https://github.com/aurora-silicon/linux/discussions/128)
lacks the wireless board nodes in the October 2026 snapshot.
[J700](https://github.com/aurora-silicon/linux/discussions/72) has PCIe groundwork,
not a complete Linux radio stack. M4 has not been assessed yet.

## Windows

Wi-Fi and Bluetooth are recorded as working on
[`j414s`](../../feature-support/m2.md#support). Those are Windows results for
that machine; the Linux work above does not establish support on the others.
The driver implementation notes still need writing up.
