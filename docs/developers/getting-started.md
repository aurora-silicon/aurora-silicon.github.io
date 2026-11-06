---
title: Getting Started
---

# Getting Started

This section is for people who want to work on Aurora Silicon itself. If you
want to run Windows or Linux on a Mac, the [user guide](../users/getting-started.md)
is the place to start.

!!! warning "Draft"

    The source map below provides entry points. Hardware setup and build
    instructions are still outlines; check the relevant repository for current
    requirements.

## What you'll need

*To write: the hardware and host setup expected of a contributor — which Mac to
develop against, what to develop from, and whether a second machine is required
for tethered work. Say plainly which parts are optional.*

## The repositories

These are public source entry points. Consult each repository's README,
`AGENTS.md` and branch documentation before building; a repository's existence
does not establish that it supports your target machine.

| Area | Source entry point | Scope |
| --- | --- | --- |
| Boot and experimentation | [m1n1](https://github.com/aurora-silicon/m1n1) | Low-level boot and hardware work; integration varies by target |
| Linux | [linux](https://github.com/aurora-silicon/linux) | Kernel drivers and device trees |
| Boot firmware | [U-Boot](https://github.com/aurora-silicon/u-boot) | Bootloader work; check the target branch |
| Windows firmware | [mu](https://github.com/aurora-silicon/mu) | Project Mu implementation for Apple Silicon |
| Windows installer | [aurora-installer](https://github.com/aurora-silicon/aurora-installer) | Windows installer development; not a Linux installation guide |
| Website | [aurora-silicon.github.io](https://github.com/aurora-silicon/aurora-silicon.github.io) | Platform guides, support records and research notes |

Additional component access and target branches should be confirmed with the
team. The [Windows](../platforms/windows.md) and [Linux](../platforms/linux.md)
guides explain which results are currently documented.

## Getting the source

*To write: how to clone what you need, including submodules, and which branch to
start from. Note anything that must sit on a case-sensitive filesystem.*

## Your first build

*To write: the shortest path from a fresh clone to a build that produces
something, so a new contributor gets a working result before learning the rest.*

## Getting a machine ready to test on

*To write: what has to be true of a Mac before you can load your own build onto
it, and how to recover it when a build does not boot. Link to
[feature support](../feature-support/overview.md) so people can check what state
their hardware is in.*

## Where to ask

*To write: which channel to use for development questions, and what to include
when asking about a failure.*

## Next steps

Once you can build, see [Development/Tooling](development-tooling.md) for the
toolchain in detail, [Testing](testing.md) for how results are recorded, and
[Contributing](contributing.md) before you send anything back.
