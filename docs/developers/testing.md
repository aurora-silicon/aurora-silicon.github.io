---
title: Testing
---

# Testing

How work gets checked before it is trusted, and how results on real hardware are
recorded.

## What we test

A build tells us the code compiles. A source review tells us which drivers and
board descriptions exist. Neither tells us that the machine works.

Hardware results need the exact device ID, operating system and software
revisions. Test the feature you are claiming, including the transitions that
matter — reconnecting a device, rebooting, or suspending and waking the machine.
Record how many attempts passed as well as what happened once.

## Running the tests

Use the instructions in the repository and branch you are working on. There is
no single build, flash or recovery command for every machine. Keep the commands
and their output with the result, and establish the recovery procedure before
changing firmware or boot components.

## Recording a result

A result belongs to one machine. Do not carry it across to another board because
it uses the same chip, or from Linux to Windows because the hardware is the same.
The [feature-support pages](../feature-support/overview.md) keep those results
separate.

Name the branch as well as the commit. A merged change may live in a feature
branch rather than the working tree, and an open PR can work on hardware without
being part of a release. Keep partial results and known limits attached to the
claim.

## Reporting a failure

Use the product thread linked from the machine's generation page, with one
feature or failure per report. An untested machine is not a reproduced bug.
Include the expected result, what happened instead, and enough detail for
someone else with that board to repeat it.

## Hardware-report template

```text
Operating system and version:
Board ID:
SoC ID and chip variant:
Model / screen size / port configuration:
Feature:
Repository / branch / commit:
Kernel or Windows build and driver versions:
m1n1 / U-Boot / UEFI / Mesa versions, where relevant:
Firmware version:
Test commands and attached devices:
Steps to reproduce:
Expected result:
Observed result:
Successful attempts / total attempts:
Reboot / reconnect / suspend tests performed:
Public log or artifact URL:
Artifact SHA-256:
Command to repeat the check:
Known limits and recovery steps:
```

This follows the reporting format in the [hardware discussions](https://github.com/aurora-silicon/linux/discussions/70).
Keep reports within Aurora Silicon spaces, as set out in
[Policies & Guidelines](../project/policies-and-guidelines.md).
