---
title: Testing
---

# Testing

A useful result identifies the operating system, exact board, feature and software that was tested. The [feature-support catalog](../feature-support/overview.md) keeps Windows results separate from the [Aurora Linux assessments](../feature-support/linux/overview.md).

## What a check establishes

| Check | What it establishes | What still needs evidence |
| --- | --- | --- |
| Source inspection | A driver, device match or board configuration exists in a specified revision. | Whether it builds, runs, has firmware and userspace integration, and works on the board. |
| Build or automated test | The named build or test passed under its recorded environment. | Hardware operation and complete-system readiness. |
| Hardware feature test | A specific feature behaved as reported on the named board and build. | Other boards, other configurations, untested transitions and long-term reliability. |
| Complete-system qualification | The recorded installer, boot chain and system passed the stated end-to-end checks. | Any scenarios or hardware absent from those checks. |

A successful build is not a hardware pass. A merged PR is not automatically a released feature: record the destination branch. In the 1 October 2026 Linux assessment, a merge into `feat/sep` remains separate from the `aurora-wip` baseline. See the [evidence legend](../feature-support/linux/overview.md#reading-the-evidence).

## Running tests and preparing hardware

Use the instructions belonging to the exact repository and branch being tested. There is no single build, flash or recovery command that applies to every board. Record the actual command, environment and exit result; confirm the board-specific recovery procedure before changing firmware or boot components.

A device-tree entry, driver option or successful boot is not enough to qualify all peripherals. Test the claimed operation and transitions explicitly: for example, both USB connector orientations, reconnects, storage resets, or suspend/resume. Only report the scenarios actually exercised. Avoid treating speaker routing as validated speaker tuning or a compile-tested camera series as working capture.

## Hardware-report template

Post one feature or failure per report. Identify the configuration from the [product directory](../feature-support/linux/overview.md#find-a-product-or-board), and keep the original limits with every quoted result.

```text
Operating system and version:
Board ID:
SoC ID and chip variant:
Model / screen size / port configuration:
Feature or SoC block:
Repository / branch / exact commit:
Kernel or Windows build and driver revisions:
m1n1 / U-Boot / UEFI / Mesa revisions, where relevant:
Firmware version:
Host tools and test commands:
Attached devices / cables / ports / orientations:
Steps to reproduce:
Expected result:
Observed result:
Successful attempts / total attempts:
Boot / reboot / suspend / reconnect scenarios tested:
Public log or artifact URL:
Artifact SHA-256:
Command to repeat the check:
Known limits / untested scenarios:
Recovery steps:
```

## Recording a result

Record results against the device ID and operating system, never against a chip or marketing name alone. A sibling board stays unverified until evidence identifies it. Preserve failures and partial results, including repeat counts and recovery conditions.

For Linux, use the evidence categories in the product assessment. For Windows, update a recorded state only when Windows evidence establishes that feature for that board. Keep a source link and assessment date, and identify any open PR or feature branch required to reproduce it.

## Reporting a failure

Reply to the product's canonical GitHub discussion, linked from its assessment. Include the smallest reproducible case and the expected result, observed failure, revisions and public artifact. An unaudited board is not a bug by itself; a missing source path, an untested feature and a reproduced failure are different findings.

Keep reports within Aurora Silicon spaces under the project's [Policies & Guidelines](../project/policies-and-guidelines.md). The report structure is adapted from the [hardware directory](https://github.com/aurora-silicon/linux/discussions/70) and [J700 assessment](https://github.com/aurora-silicon/linux/discussions/72), dated 1 October 2026.
