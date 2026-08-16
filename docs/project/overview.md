---
title: Project Overview
---

# Project Overview

Aurora Silicon is working to bring Windows on ARM to Apple Silicon Macs. This
page is the wider picture: what the problem actually is, how the project is put
together, and how we decide what we are willing to claim.

!!! warning "Partly drafted"

    The sections describing the project and how it works are settled. Those
    covering the technical approach and current position are still marked as
    outstanding.

## The problem

An Apple Silicon Mac does not boot the way a PC does. Apple's machines come up
through their own boot chain and describe their hardware with an Apple-specific
device tree. Windows on ARM expects neither of those things — it expects UEFI
firmware and ACPI tables.

So the work splits roughly into three parts. Something has to take over from
Apple's firmware and hand control to a bootloader Windows understands. That
bootloader needs to describe Apple's hardware in terms Windows can read. And
then every piece of hardware in the machine — display, storage, input,
networking — needs a driver, because none of Apple's exist for Windows.

Very little of this is a matter of writing code against documentation. Apple
does not publish the interfaces involved, so most of the effort is working out
what the hardware does before anything can be written for it.

## The technical approach

*To write: the actual boot chain we are building, component by component, and
where each piece comes from — what we fork, what we write, and what we take as
it ships. Keep it to a page; the detail belongs under
[Research](../research/overview.md) and in the repositories.*

## How the project is organised

*To write: what our repositories are and how they relate — which holds the
bootloader, which the kernel work, which the installer, and which the
per-platform bring-up. The [developer guide](../developers/getting-started.md)
covers this for contributors; here it only needs enough for a reader to
understand the shape.*

## How we track support

Support is recorded per machine, never per chip. Apple ships one chip across
several different machines, and a result on one does not transfer to a sibling —
the silicon may be shared but the board, display and peripherals are not. Every
machine is recorded against its own device ID, and a feature with no recorded
state means untested rather than working.

The full catalog, and the current state of each machine, is under
[feature support](../feature-support/overview.md).

## Where the project is now

*To write: an honest summary of the current position — which machines are being
actively worked on, what the nearest milestone is, and what is deliberately not
being attempted yet. This section will date faster than the rest of the page, so
keep it short and keep it current.*

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
