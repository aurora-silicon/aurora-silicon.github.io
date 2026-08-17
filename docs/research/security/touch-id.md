---
title: Touch ID
---

# Touch ID

Notes on the Touch ID stack and a reverse-engineered C reimplementation of the
AP side of it, targeting a custom OS — Asahi Linux and Windows on Arm.

Around 4,150 lines of C plus 1,050 lines of Python bring-up tooling, MIT
licensed. This is research. Nothing in it has authenticated a fingerprint; the
protocol layers are recovered and written, and the paths that would exercise a
sensor return `-ENOSYS`. Roughly 30 items remain marked `TODO_RE` pending a live
mailbox capture.

The work is built from static RE of the on-disk kexts and frameworks
(`nm`/`otool`/`kmutil`, plus the decompressed boot kernelcache), from m1n1's
`hw/sep.py` and `hw/asc.py`, and from the public RE record.

## Two targets

Built-in and external Touch ID are different problems with different trust
boundaries.

| | Built-in (MacBook) | Magic Keyboard with Touch ID |
| --- | --- | --- |
| Sensor owner | SEP, factory-paired SPI | Keyboard PKA block, factory SPI |
| Matcher | SEP `BioApp` | **Mac SEP** — the keyboard is a proxy |
| Pairing authority | None; sensor is wired to its SEP | ECDHE P-256, Apple-CA attested |
| Endpoint | SBIO `0x08` | stac `0x18`, USB iface 2 EP `0x85` |

The keyboard does not match. Apple's own platform security documentation states
that the keyboard performs the role of the sensor and does not store templates,
perform matching, or enforce policy — the Mac's Secure Enclave does all three,
exactly as for a built-in sensor. A keyboard pairs to one Mac at a time; a Mac
holds up to five pairings.

## Stack

| Layer | Component | Owner |
| --- | --- | --- |
| Userspace | `LAContext` → `coreauthd` → `biometrickitd` | macOS |
| Kernel | `AppleBiometricServices`, `AppleMesaSEPDriver`, `AppleSEPManager` | macOS |
| Transport | ASC mailbox at base `+0x8000`, IOMMU `dart-sep` | AP |
| Matcher | SEPOS `BioApp`, template "catacomb" | SEP |
| Sensor | Mesa module over SIO SPI-I/O DMA | SEP owns the protocol, AP owns the hardware |

Templates never cross to the AP.

## Mailbox

A 64-bit word. The SEP is unique among Apple ASC coprocessors in carrying the
endpoint in the low bits of the *first* register; AOP, DCP, ISP and SIO use the
second.

| Bits | Field |
| --- | --- |
| 0–7 | Endpoint |
| 8–15 | Tag |
| 16–23 | Type / opcode |
| 24–31 | Param |
| 32–63 | Data — pointer, IOVA page frame, or scalar |

Endpoints relevant here: `0x00` control, `0x08` SBIO, `0x12` SKS, `0x13` xART,
`0x18` stac, `0xFD` discovery, `0xFE`/`0xFF` boot. This matches the endpoint
table in the [Asahi Linux SEP documentation](https://asahilinux.org/docs/hw/soc/sep/).

## SEPOS boot

`GET_STATUS → BOOT_TZ0 → GET_STATUS → BOOT_IMG4 → SET_SHMEM → BOOT_IMG4_DONE`,
with the shared-memory image a header of `{name[4], size, offset}` descriptors
(`CINP` panic, `OPLA` and `IPIS` manifests, `llun` terminator). The C port is a
direct translation of m1n1's implementation.

T8110 and later add cold-bootrom steps absent from m1n1's opcode enum — iBIC KCV
capture, ART load, TMM manifest and patch images. Omitting them is what makes
SEPOS bring-up fail on M2 and newer.

## SBIO — two command spaces

The endpoint has two numbering schemes that must not be conflated. `bm_cmd_t`
(magic `0x4d42`, opcodes `1..0x62`) is the AP and userland header, dispatched
through a 97-entry jump table. It is never placed on the wire raw. The driver
maps it to an SBIO wire `TYPE` in roughly `0x14..0x92`, carried by
`AppleSEPGenericTransfer` — a transaction and fragmentation layer that adds no
crypto.

That last point matters: static RE of the AP kexts found **no** Diffie-Hellman
or per-session key handshake on the mailbox. Any session crypto lives inside
encrypted SEPOS, invisible to the AP, so a client sends raw opcodes and ferries
out-of-line buffers rather than wrapping or MACing anything.

The operation split is the important structural finding:

| Class | Path | State |
| --- | --- | --- |
| Template, catacomb, identity, lockout, calibration, xART probe, factory | Direct SBIO `TYPE` via the transaction layer | Implemented |
| Enroll, match, enroll-continue, finger detect, cancel, reset | SEP-driven SPI sensor path, not the mailbox | `-ENOSYS` |

Out-of-line buffers are 16 KB in and 5 MB out. The result-code enum and
per-payload field offsets are a SEP-side contract and remain unrecovered.

`seaCookie` turned out not to be a command wrapper but sensor factory
provisioning — a 12-state machine installing a sensor root key that the SEP
generates and the AP never sees.

## Sensor transport

The Mesa sensor is driven over Apple's SIO coprocessor, the SPI-I/O DMA engine,
not by AP SPI MMIO writes. The AP programs `dart-sio`, powers the sensor over a
GPIO, and talks the SIO mailbox; DMA channels `0x18` TX and `0x19` RX carry a
capture record of about `0x7200` bytes.

The command buffer the SEP sends the sensor is SEP-encrypted. The AP sees the
DMA envelope — channels, sizes, IOVAs — and never the plaintext commands or raw
frames. AP-owned hardware, SEP-owned logical protocol.

## External keyboard

USB interface 2, bulk endpoint `0x85`, is the secure transport; Bluetooth is
BR/EDR Classic, not BLE. Pairing is mutual Apple-CA-attested ECDHE P-256, with
per-session AES-GCM-256 from an ephemeral exchange. The handshake is
`kGT_QUERY → kGT_PAIR_CRYPTO → kGT_PAIR_FINALIZE`; the SEP holds the derived key
and the AP ferries records between USB and stac.

Session keys roll on a timer clamped to 60 seconds to 24 hours, re-deriving via
HKDF-SHA256 salted with the previous key. A lost session unpairs.

One naming correction worth recording: `SNEPKc` is Itanium C++ mangling for
`char const*` — *serial number*, not "Secure Neural Engine". The AP compares
serial-number strings only. The certificate chain verify is SEP-side.

## Blockers

| # | Blocker | Why it holds |
| --- | --- | --- |
| 1 | SEPOS bootstrap under a custom OS | Asahi sleeps the SEP before Linux starts; no Linux driver re-runs the SEPROM handshake |
| 2 | SEP firmware is signed and encrypted under a separate GID | The AP cannot decrypt or replace it. You run Apple's matcher or none |
| 3 | Sensor-path opcodes | Management ops recovered; enroll and match need a live EP `0x08` trace |
| 4 | Sensor↔SEP SPI is factory-paired AES-CCM | The AP cannot drive the sensor or read frames, only ask the SEP to |
| 5 | Keyboard pairing is Apple-CA attested end to end | The verify happens in Apple-signed SEPOS, so no AP-side code can satisfy it |

Blocker 5 leaves two paths: clone a paired keyboard's stored identity, which
requires extracting a PKA identity not known to be exposed; or run genuine
signed SEPOS and let it perform the pairing. The second reduces the external
keyboard to the built-in problem and is the one this work targets.

## Current position

The bring-up target is `j414s`, an M2 Pro machine — see
[feature support](../../feature-support/m2.md). The gating problem is reaching a
live SEPOS: the SEP self-power-gates under a warm m1n1 proxy, so the approach is
a cold-boot catch that probes the mailbox inside the window after iBoot boots
SEPOS and before it gates itself.

The first proof target is deliberately small — endpoint discovery followed by a
single `get_catacomb_state` round trip. One acknowledgement validates the
message bit-packing, transaction correlation, out-of-line registration and a
real opcode at once, before any biometric operation is attempted.

## Out of scope by design

- Reading or relaying raw fingerprint pixels. The sensor↔SEP link is encrypted
  and factory-paired; the AP never sees frames.
- Reusing macOS-enrolled templates. They never leave the SEP, so a custom OS
  re-enrols.
- Minting an Apple-CA-attested SEP identity for clean keyboard pairing.

## Sources

Asahi Linux [SEP documentation](https://asahilinux.org/docs/hw/soc/sep/);
Apple's [Platform Security guide](https://support.apple.com/guide/security/magic-keyboard-with-touch-id-secf60513daa/web);
Mandt, Solnik and Wang, *Demystifying the Secure Enclave Processor* (Black Hat
2016); checkra1n/PongoOS `sep.c`; hack-different `apple-knowledge`; m1n1
`hw/sep.py` and `hw/asc.py`; CVE-2024-0230; Khaos Tian's "Magic Button".
