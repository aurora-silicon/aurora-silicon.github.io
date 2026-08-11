---
title: FAQ
---

# Frequently asked questions

## Can I install this on my Mac?

Not as a supported thing, no. There is no installer and no supported path.

Running it means test signing, modified boot policy, a matching m1n1 and Project
Mu build for your exact machine, and a tethered host for debugging and recovery.
It can crash Windows, corrupt data, or leave the machine needing recovery. Only
do this on hardware and data you can afford to lose.

## Does Windows actually run?

Yes. On a MacBook Pro 14-inch M2 Pro it boots to a desktop from the internal SSD,
with the GPU rendering and presenting frames to the physical console.

It is not finished. The desktop is not GPU-accelerated yet (that needs the WDDM
path), SMP is in progress, and wireless is still being brought up. See
[Hardware support](../platform/support.md) for the current feature table.

## Which Macs work?

M2 Pro is the primary and most validated target — specifically the MacBook Pro
14-inch (`j414s`). M1 Pro was the earlier bring-up machine and is behind. The M5
MacBook Air (`j813`) is in active preliminary bring-up: m1n1 and UEFI boot,
read-only internal-storage discovery works, and Windows Setup has launched, but
there is no complete installation or general hardware support yet.

MacBook Neo (8 GB / 256 GB) and M3 Max MacBook Pro have not been tested and are
unsupported. Unlike GPU work, Windows bring-up does not generalise between
machines: ACPI tables, device trees and firmware profiles are per-model.

## Is the GPU actually working, or is it software rendering?

Actually working. Honeykrisp advertises Vulkan 1.4.354 on hardware, Direct3D 11
runs through DXVK at feature level 11.0, and presentation has been validated
across 1,200-frame runs on the physical console.

What is *not* done is the WDDM miniport, which is what would make the Windows
desktop itself accelerated. That is in bring-up.

## Is the Vulkan implementation conformant?

No, and it should not be described that way. It advertises 1.4.354 and runs real
workloads, but no Vulkan CTS profile has been run — no dEQP binary is staged on
the machine. "Works" and "conformant" are different claims and only the first is
currently supported by evidence.

## Can I play games?

Not yet, and this is not the project to use if that is your goal today. Direct3D
11 titles are the closest thing to plausible, but the desktop is not accelerated
and large parts of the platform are still being brought up.

## What is d3d12agx, and is it what runs my games?

No. [d3d12agx](../projects/d3d12agx/index.md) is a separate research project on
**Linux** — a native Direct3D 12 driver for the Apple GPU with no Vulkan layer.

Direct3D 12 on the Windows stack goes through vkd3d-proton on Vulkan, like it
does on Linux under Proton. d3d12agx is an experiment in removing that hop; if it
matures and is ported, it would replace vkd3d in the chain.

## Is this affiliated with Asahi Linux?

No. Aurora Silicon is an independent experimental effort, not an official product
of — or supported by — Asahi Linux or the upstream NT-for-ASi project.

It builds on public work from both, and would not exist without them. Please do
not report bugs caused by these experimental drivers to either project unless one
of their maintainers explicitly asks. Report them here.

## Was this built with AI?

Substantial parts, yes — and it is stated in the repository README as well as
[here](method.md).

That is why the evidence standards are what they are. Hardware traces, host tests
and repeatable builds are what validate a change; fluent-looking code is not
evidence. Treat every implementation as untrusted until proven on your exact
target.

## How do I report a problem?

Include the exact Mac model and SoC, Windows build and image type,
driver/firmware/m1n1 commit IDs, package and payload hashes, and the complete
serial, hypervisor and debugger logs. Symptoms and photos help but do not replace
logs.

[GitHub](https://github.com/aurora-silicon) or
[Discord](https://discord.gg/DXmsSSc5aY) — contact `djdev` or `rttdev`.
