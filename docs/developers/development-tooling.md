---
title: Development/Tooling
---

# Development and Tooling

The toolchain, the debug hardware, and the day-to-day loop of building something
and getting it onto a machine.

!!! warning "Draft"

    This page is an outline. The sections below describe what still needs to be
    written, and no technical detail here should be treated as accurate yet.

## Toolchain

*To write: the compilers and language toolchains required, with versions. The
bootloader needs an `aarch64` cross-compiler and a bare-metal Rust target;
confirm the exact requirements against the tree rather than copying them from
upstream, since our fork may have moved.*

## Host setup

*To write: what the development host itself needs — supported host operating
systems, packages, and any host-side kernel requirements. Some of our debug
tooling only runs on a Linux host, which is worth stating early.*

## Debug hardware

*To write: the cables, adapters and second machines needed for tethered debug,
and what each one buys you. Be specific about cable requirements — the wrong
USB-C cable silently fails rather than erroring.*

## Host tools

*To write: the tools used to talk to a target — what each one does, when you
reach for it, and how to tell it is working. Note which are used as upstream
ships them and which we carry patched.*

## Building

*To write: the build invocations for each tree, what artefacts they produce, and
where those artefacts end up. One subsection per tree.*

## Loading a build onto a target

*To write: the loop of getting a build onto hardware and back out again,
including the recovery path when it does not come up.*

## Working with agents

*To write: our repositories carry agent instruction files. Explain what they are
for and what a contributor should know about them.*
