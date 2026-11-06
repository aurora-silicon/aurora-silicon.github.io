---
title: Project Overview
---

# Project Overview

Aurora Silicon develops Windows and Linux support for Apple Silicon Macs,
alongside boot firmware and hardware research. This page explains how those
parts fit together and how we track what works. Start with
[Platforms](../platforms/overview.md) for the individual operating systems.

## The problem

An Apple Silicon Mac does not boot the way a PC does. Apple's machines come up
through their own boot chain and describe their hardware with an Apple-specific
device tree. Windows on ARM expects neither of those things — it expects UEFI
firmware and ACPI tables.

Linux needs its own kernel drivers, device descriptions and boot integration.
The hardware knowledge can be shared, but the operating-system interfaces and
validation differ. Neither a Windows driver nor a Linux driver proves support
on the other OS.

Apple does not publish many of the hardware interfaces involved, so a large
part of the work is understanding the hardware before implementing drivers.

## The technical approach

The work has three connected layers:

- **Boot and hardware foundations:** m1n1, firmware integration and tools for
  understanding and bringing up individual machines.
- **Operating-system integration:** UEFI, ACPI and HAL/driver work for Windows;
  kernel, device-tree and boot integration for Linux.
- **Subsystems and research:** graphics, networking, power and other hardware
  features, with results qualified by the OS and machine used.

These layers describe the work, not a single installation chain used by every
machine. The exact components and revisions belong in each platform's testing
and installation documentation.

## How the project is organised

The [developer guide](../developers/getting-started.md) links the public source
entry points for boot firmware, Linux and Windows integration. The
[research notes](../research/overview.md) cover hardware findings and explain
which OS a particular implementation targets.

## How we track support

Support is recorded per machine and operating system, never per chip alone. Apple ships one chip across
several different machines, and a result on one does not transfer to a sibling —
the silicon may be shared but the board, display and peripherals are not. Every
machine is recorded against its own device ID, and a feature with no recorded
state means untested rather than working.

The full catalog, and the current state of each machine, is under
[feature support](../feature-support/overview.md).

## Where the project is now

The site records experimental Windows results for `j316s` and `j414s`. Linux
per-machine feature records and validated installation guides for both OSes are
still outstanding. The [platform guides](../platforms/overview.md) distinguish
those documentation gaps from the work described in the research pages.

## Who works on it

A small team, listed under [Meet The Team](team.md). Between them they hold the
hardware the project is brought up on, which is why the primary targets on each
[feature support](../feature-support/overview.md) page are named against people.

## What we build on

A great deal of this project rests on work done by others — the reverse
engineering that made Apple Silicon legible at all, prior attempts at booting
Windows on it, and the firmware and graphics stacks underneath. Those projects
and people are credited under [Attribution](attribution.md).

## How we work

Two things shape how the project operates, and both are worth knowing before you
get involved.

The first is provenance. We are strict about where code comes from: no
NDA-protected or non-public material, conditions on contributions from Apple and
Microsoft employees, and mandatory disclosure when generative AI has been
involved in a submission.

The second is that we do not upstream our work. Findings, patches and
reverse-engineering results from this project stay in Aurora Silicon spaces and
are not sent to Asahi Linux, NT-for-ASi or any other upstream. Our approach
differs enough from theirs that our output would be unusable to them — the rule
exists to protect their work, not to hoard ours.

Both are set out properly in [Policies & Guidelines](policies-and-guidelines.md).

## Getting involved

If you want to run it, start with the [user guide](../users/getting-started.md).
If you want to work on it, start with the
[developer guide](../developers/getting-started.md). Either way, the project is
experimental and the honest state of any given machine is on its
[feature support](../feature-support/overview.md) page.
