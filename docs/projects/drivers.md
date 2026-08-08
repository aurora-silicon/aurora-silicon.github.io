---
title: Drivers
---

# Drivers

Windows expects PC hardware. Apple Silicon provides none of it — a different
interrupt controller, a different IOMMU, Apple's own storage, display, power and
sensor controllers. Every one needs a driver written from public documentation
and hardware traces.

There are **43 driver projects** in tree. They are experimental: presence here
means work exists, not that it is finished or safe.

## Platform foundation

| Driver | Role |
| --- | --- |
| `AicHal` | HAL extension for the Apple Interrupt Controller — lets Windows drive AIC2 natively instead of emulating a GIC |
| `AppleAic` | AIC2 interrupt controller |
| `AppleDart` | Apple's IOMMU, in front of most peripherals |
| `AppleDapf` | DART address-filter companion |
| `AppleRtkit` | RTKit — the protocol Apple's coprocessors speak |
| `ApplePmgr` | Power manager |
| `AppleClk` | Clock control |
| `AppleCpuFreq` | CPU frequency |
| `AppleSmc` | System Management Controller |
| `AppleSmcBattery`, `AppleSmcGpio` | SMC-attached battery and GPIO |
| `AppleEfuse` | Fuse/identity readout |
| `AppleWdt` | Watchdog timer |
| `AppleGpio`, `AppleSpmi` | GPIO and SPMI buses |

## Storage, PCIe and USB

| Driver | Role |
| --- | --- |
| `AppleNvme` | Apple's NVMe/ANS storage controller — how Windows boots from internal SSD |
| `ApplePcie` | PCIe root complex |
| `AppleUsb4` | USB4/Thunderbolt |
| `AppleUsbDwc3` | DWC3 USB controller |
| `AppleXhciAffinity` | xHCI interrupt affinity |
| `AppleTypeC` | Type-C port control |
| `AppleSdhc` | SD host controller |
| `AuroraUsbBot` | USB bulk-only transport helper for bring-up |

## Graphics and display

| Driver | Role |
| --- | --- |
| `AppleAgxGpu` | KMDF render node for the AGX GPU — see [Graphics](gpu.md) |
| `AppleAgxWddm` | WDDM display miniport, in bring-up |
| `AppleGpu` | GPU platform glue |
| `AppleDcp` | Display Coprocessor |
| `AppleDisplay` | Display pipeline and scanout state |

## Input, audio and sensors

| Driver | Role |
| --- | --- |
| `AppleSpiHid` | SPI HID — the built-in keyboard and trackpad |
| `AppleMtpHid` | Multi-touch HID transport |
| `AppleKbdBacklight` | Keyboard backlight |
| `AppleLidAngle` | Lid angle sensor |
| `AppleAopAudio` | Always-On Processor audio |
| `AppleMcaAudio` | MCA audio |
| `AppleIsp` | Image signal processor (camera) |
| `AppleI2c`, `AppleSerial`, `AppleUart`, `AppleSio` | Buses and serial transports |

## Wireless

| Driver | Role |
| --- | --- |
| `AppleBcmWifi` | Broadcom Wi-Fi |
| `AppleBcmBluetooth` | Broadcom Bluetooth |
| `AppleBcmCommon` | Shared Broadcom transport and firmware loading |

## Building

Each driver has its own README listing build requirements and limitations; those
are more authoritative than any overview. A single entry point drives host
operations:

```console
tools/driver list
tools/driver build usb-dwc3
tools/driver test usb-dwc3
tools/driver package usb-bot
tools/driver test all
```

`tools/driver list` reports which operations exist per component. Drivers without
a native macOS recipe must be built from their Visual Studio project with the
WDK.

Windows driver and HAL-extension builds generally need Visual Studio 2022 Build
Tools, the matching Windows 11 SDK and WDK, an ARM64 build environment, and a
test-signing setup. HAL-extension signing additionally requires certificates and
Microsoft binaries that are **not distributed here**.

End-to-end build, boot, logging, recovery and guest control are handled by the
`auroradbg` project through its `abg` CLI.

## Reporting problems

A useful report includes the exact Mac model and SoC, the Windows build and image
type, driver/firmware/m1n1 commit IDs, package and payload hashes, and the
complete serial, hypervisor and debugger logs.

Photos and symptoms help but do not replace logs — and avoid testing several
unrelated changes in one hardware boot, because the result is then attributable
to none of them.
