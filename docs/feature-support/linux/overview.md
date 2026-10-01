---
title: Aurora Linux Evidence
---

# Aurora Linux evidence

**25 product assessments · 59 board configurations · snapshot dated 1 October 2026**

Find your product below, then use its board ID to read the relevant implementation evidence, hardware reports and remaining gaps. Screen sizes, port configurations and Pro / Max / Ultra variants stay together in each product's configuration table.

!!! info "Linux and Windows are recorded separately"

    These pages describe Aurora Linux. For Windows bring-up results, use the device dialogs and Windows support sections in the [generation catalogs](../overview.md). Linux driver code, a Linux boot or a Linux hardware report does not establish Windows support.

## Assessment coverage

The source baseline is [`aurora-wip` at `1d2904fd3301`](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6). Public feature branches and open PRs are recorded separately, with their tested boards and limits. **M1–M3 cover 35 boards across 14 product assessments.** J700 has its own public assessment. M4–M6 remain pending; that does not mean unsupported.

| Family | Boards | Linux assessment |
| --- | ---: | --- |
| [A18 Pro](../a18-pro.md) | 1 | Public J700 work and named hardware reports; graphics, radios, deeper sleep and complete installation remain incomplete. |
| [M1](../m1.md) | 11 | 11 boards assessed in source. AGX/DCP and platform integration are present; hardware reports are limited to named boards and builds. |
| [M2](../m2.md) | 12 | 12 boards assessed in source. Platform and graphics integration are present; board exceptions and development branches remain explicit. |
| [M3](../m3.md) | 12 | 12 boards assessed in source. Platform work is present; GPU and full DCP paths are missing in the audited public tree. |
| [M4](../m4.md) | 12 | 12 catalog entries; Linux assessment pending. |
| [M5](../m5.md) | 10 | 10 catalog entries; Linux assessment pending. Pro / Max / Ultra identity mapping is source-qualified. |
| [M6](../m6.md) | 1 | 1 catalog entry; Linux assessment pending. |

## Find a product or board

| Family | Product assessment | Board IDs |
| --- | --- | --- |
| A18 Pro | [MacBook Neo](a18-macbook-neo.md) | `j700` |
| M1 | [iMac](m1-imac.md) | `j456`, `j457` |
| M1 | [Mac mini](m1-mac-mini.md) | `j274` |
| M1 | [Mac Studio](m1-mac-studio.md) | `j375c`, `j375d` |
| M1 | [MacBook Air](m1-macbook-air.md) | `j313` |
| M1 | [MacBook Pro](m1-macbook-pro.md) | `j293`, `j314s`, `j316s`, `j314c`, `j316c` |
| M2 | [Mac mini](m2-mac-mini.md) | `j473`, `j474s` |
| M2 | [Mac Pro](m2-mac-pro.md) | `j180d` |
| M2 | [Mac Studio](m2-mac-studio.md) | `j475c`, `j475d` |
| M2 | [MacBook Air](m2-macbook-air.md) | `j413`, `j415` |
| M2 | [MacBook Pro](m2-macbook-pro.md) | `j493`, `j414s`, `j416s`, `j414c`, `j416c` |
| M3 | [iMac](m3-imac.md) | `j433`, `j434` |
| M3 | [Mac Studio](m3-mac-studio.md) | `j575d` |
| M3 | [MacBook Air](m3-macbook-air.md) | `j613`, `j615` |
| M3 | [MacBook Pro](m3-macbook-pro.md) | `j504`, `j514s`, `j516s`, `j514c`, `j516c`, `j514m`, `j516m` |
| M4 | [iMac](m4-imac.md) | `j623`, `j624` |
| M4 | [Mac mini](m4-mac-mini.md) | `j773g`, `j773s` |
| M4 | [Mac Studio](m4-mac-studio.md) | `j575c` |
| M4 | [MacBook Air](m4-macbook-air.md) | `j713`, `j715` |
| M4 | [MacBook Pro](m4-macbook-pro.md) | `j604`, `j614s`, `j616s`, `j614c`, `j616c` |
| M5 | [Mac mini](m5-mac-mini.md) | `j873s` |
| M5 | [Mac Studio](m5-mac-studio.md) | `j775c`, `j775d` |
| M5 | [MacBook Air](m5-macbook-air.md) | `j813`, `j815` |
| M5 | [MacBook Pro](m5-macbook-pro.md) | `j704`, `j714s`, `j716s`, `j714c`, `j716c` |
| M6 | [Mac mini](m6-mac-mini.md) | `j873g` |

## Reading the evidence

| Marker | Meaning |
| --- | --- |
| 🟢 Reported on hardware | A cited report identifies the exact board and tested feature. Its software revisions and limits remain part of the result. |
| 🔵 Published / integrated source | Public code or an enabled board description exists. “Integrated” refers to the pinned branch, not every release. Neither label alone proves operation on hardware. |
| 🟠 Development / partial | An open PR, separate feature branch, incomplete configuration, functionality or qualification remains. |
| ⚪ Not audited / unverified | This assessment has not established the capability for the board. Absence of evidence is not a tested failure. |
| 🔴 Known / source gap | The cited hardware report or pinned source identifies a failing capability, missing match or disabled board path. Read the stated boundary. |
| — Not fitted | The product does not contain that hardware. |

Implementation, compilation, a hardware test and a usable complete system are separate milestones. A result on one board never transfers automatically to a sibling. A merge must name its destination branch: for example, `feat/sep` is separate from `aurora-wip`. Open and draft PRs remain development work even when a contributor reports a successful test.

## Identity and provenance

The catalog follows the [public hardware directory, discussion #70](https://github.com/aurora-silicon/linux/discussions/70), maintained by [Acelogic](https://github.com/Acelogic). Each product page preserves its original discussion, snapshot date, public identity references, pinned device-tree and driver links, and board-specific evidence.

M5 Pro, Max and Ultra are listed as `t6050` in the directory's cited identity source. Keep their board IDs and marketing variants distinct: the shared catalog ID does not establish identical dies, firmware, drivers or support. M4–M6 catalog entries and catalogue years are identity records, not confirmation of a tested installation.

This is a dated publication of the evidence, not an automatic feed. The linked discussions contain subsequent reports and corrections. Existing consolidated discussion URLs remain the canonical place to contribute; old per-board and SoC threads are archived redirects.

## Reporting and related research

Use the [hardware-report template](../../developers/testing.md#hardware-report-template) and post one feature or failure in the matching product discussion. Record the operating system, exact board and software revisions, repeat count, public logs and artifact hash. Use `soc:Txxxx` labels to find related discussions without transferring a result between boards.

The [Linux platform research summary](../../research/linux-platform.md) connects the Touch ID, display, storage, audio, camera and power findings to their underlying evidence.

