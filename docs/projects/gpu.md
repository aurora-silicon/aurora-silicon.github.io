---
title: Graphics
---

# Graphics on Windows

Apple's GPU has no Windows driver and no public documentation. The stack here is
built from Mesa's reverse-engineered AGX support, ported to Windows and driven
by a Windows kernel driver.

<div class="scoreboard" markdown>
<div class="cell" markdown><div class="n hero">1.4.354</div><div class="l">Vulkan advertised</div></div>
<div class="cell" markdown><div class="n hero">11.0</div><div class="l">D3D11 feature level</div></div>
<div class="cell" markdown><div class="n">1,200</div><div class="l">frames presented</div></div>
<div class="cell" markdown><div class="n">0</div><div class="l">leaked objects after teardown</div></div>
</div>

Measured on a MacBook Pro 14-inch M2 Pro (`J414s`, Apple T6020, G14S B1) running
Windows on ARM64 under the m1n1 hypervisor.

## The stack

```
    Direct3D 11 app          Vulkan app
          │                      │
          ▼                      │
     DXVK (D3D9-11)              │
          └──────────┬───────────┘
                     ▼
         Honeykrisp (Vulkan ICD, ported)
                     │
                     ▼
            AppleAgxGpu.sys
        KMDF render node, ACPI\NTAS0023\0
                     │
                     ▼
                   AGX
```

Direct3D 12 is served by a port of vkd3d-proton on the same Vulkan base.

## What works

| Capability | State | Evidence |
| --- | --- | --- |
| Vulkan API | <span class="status works">Working</span> | Honeykrisp advertises Vulkan 1.4.354 on hardware |
| Compute, buffer and image paths | <span class="status works">Passing</span> | Empty, fill, constants, shader verification, meta-clear, IMG2BUF, offscreen render and CPU readback |
| Window-system presentation | <span class="status works">Passing</span> | 20 fresh one-frame processes, 120 frames, and 1,200 frames on the physical console |
| Repeated process teardown | <span class="status works">Passing</span> | Firmware contexts, heap garbage, sync objects, VMs, BOs, queues and bindings all return to zero |
| Direct3D 11 via DXVK | <span class="status works">Working</span> | Feature level 11.0; compute 64/64 and raster/readback 8/8 |
| dxgkrnl / WDDM miniport | <span class="status wip">In progress</span> | Bring-up transaction and memory/UAT backend build and test clean; controlled hardware start is next |
| Accelerated DWM desktop | <span class="status wip">Not yet</span> | Needs the WDDM submission/fence/present path and a native D3D11 UMD DDI |

!!! warning "Working is not conformant"

    The Vulkan result is a **runtime milestone, not a Khronos conformance
    claim.** No dEQP/CTS binary is staged on the current machine.

    Do not describe the ICD as conformant until the applicable Vulkan CTS
    profile actually passes. "Advertises 1.4.354 and runs real workloads" and
    "is a conformant Vulkan implementation" are different statements, and only
    the first is currently supported by evidence.

## Components

| Path | Role |
| --- | --- |
| `drivers/AppleAgxGpu` | KMDF render node — command streams, memory, sync objects, event completion |
| `drivers/AppleAgxWddm` | WDDM display miniport, in bring-up |
| `gpu/honeykrisp-port` | Mesa's AGX Vulkan driver, cross-built for aarch64-windows |
| `gpu/dxvk-port` | DXVK — Direct3D 9/10/11 on Vulkan |
| `gpu/vkd3d-port` | vkd3d-proton — Direct3D 12 on Vulkan |
| `gpu/d3d10umd-port` | Mesa's `d3d10umd` Gallium frontend as a D3D10 UMD |
| `gpu/vktests`, `gpu/vkprobe` | Validation harnesses |

## How results are evidenced

GPU claims here carry package hashes, driver versions and log locations, so a
result can be tied to the exact binary that produced it. A recent validation run
recorded:

```text
submit_ioctl = materialize = prepare = 2690
prepare_failures  = 0
sync_wait_pends   = sync_wait_completions = 1348
wait_eval_error   = 0
VM/BO/queue/binding objects = 0
render submissions  = 1343
compute submissions = 1347
```

The zeros matter as much as the totals: every allocated object was returned, and
no wait was left unevaluated. A GPU stack that renders correctly but leaks
contexts fails differently — later, and harder to diagnose.

## Relationship to d3d12agx

[d3d12agx](d3d12agx/index.md) is a separate research effort on Linux: a native
Direct3D 12 driver for AGX with no Vulkan layer at all.

If it matures and is ported to a Windows UMD, it would replace the
`vkd3d-port → Honeykrisp` half of the chain for Direct3D 12 — one translation
layer instead of two. That is a long way off; today the shipping path for D3D12
is vkd3d-proton on the Vulkan stack described above.
