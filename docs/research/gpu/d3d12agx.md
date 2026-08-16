---
title: d3d12agx (mesa)
---

# d3d12agx

A Direct3D 12 user-mode driver for Apple's AGX GPU, written on the Mesa/Asahi
substrate. Direct3D shader bytecode is compiled straight to AGX machine code;
there is no Vulkan layer, no SPIR-V, and no dependency on Microsoft's shader
compiler.

It runs on Linux and is a research result, not part of the Windows stack. Around
39,000 lines of C, MIT licensed to match Mesa.

## Stack

| Layer | Component | Origin |
| --- | --- | --- |
| User-mode driver | d3d12agx | this project |
| Shader and GPU substrate | Mesa AGX backend, `ail` layout, genxml, libagx | Mesa |
| Kernel-mode driver | `drm/asahi` | Asahi Linux, used as-is |
| Hardware | AGX | — |

d3d12agx is a sibling of Honeykrisp, Mesa's Vulkan driver for AGX, not a layer
on top of it. Where the two program the hardware differently, Honeykrisp is
treated as correct and the divergence investigated.

It is not a translation layer: vkd3d-proton and DXVK re-emit Direct3D as Vulkan
and need a Vulkan driver beneath them. Mesa's own `d3d12` driver runs the
opposite direction — OpenGL and OpenCL on top of Direct3D 12.

## Conformance

Measured against the vkd3d-proton Direct3D 12 test suite, 557 test functions,
on an Apple M2.

| Implementation | Passing |
| --- | --- |
| d3d12agx | 553 / 557 |
| vkd3d-proton over Honeykrisp, same GPU | 505 / 557 |

The reference is not a ceiling. 25 of the 52 tests it fails were already passing
here, so that group was never platform-impossible. Two limits previously assumed
to be hardware walls were subsequently implemented: the 2,048-entry sampler heap
against AGX's 1,024 slots, via sampler-state virtualization; and sparse
residency and tile mappings, as full Tier-1 tiled resources.

### Remaining failures

| Test | Cause |
| --- | --- |
| `test_open_heap_from_address` | Requires an Asahi kernel user-memory import ABI that does not exist. Not a driver gap. |
| Two structured/raw typed-read probes | Vendor-undefined behaviour. Passing them would mean inventing semantics. |
| `test_stress_fallback_render_target_allocation_device` | Requests ~16 GiB on a 7.3 GiB machine. Needs a residency/eviction architecture. |

## Shader path

Both Direct3D container formats are read directly:

- **DXIL** (Shader Model 6) — LLVM 3.7-era bitcode with resources, entry points
  and I/O signatures in metadata, operations as `dx.op` intrinsic calls.
- **DXBC** (Shader Model 5) — older token-based instruction stream with its
  input signature in a separate `ISGN` chunk.

Both lower to NIR, then through Mesa's AGX backend to machine code.

SPIR-V was deliberately not used as an intermediate. SPIR-V requires structured
control flow and DXIL does not have it, so any DXIL to SPIR-V translator must
reconstruct structure from an arbitrary control flow graph. NIR imposes no such
requirement, which avoids the problem rather than solving it.

## Implemented

All programmable stages execute on hardware, verified pixel-exact against CPU
reference rasterisation:

- Vertex, including interleaved attributes, indexed draws with non-zero base
  vertex and start index, and instancing
- Geometry, lowered to compute dispatches ordered ahead of the render pass
- Tessellation, hull and domain, via a compute-based tessellator
- Mesh and amplification
- Pixel, including multisampling, interpolation modes and coverage

Also multiple render targets, blending, depth and stencil, queries, indirect
execution, stream output, bindless resource and sampler heaps, and GPU-readable
descriptor storage.

## Not implemented

| Gap | Detail |
| --- | --- |
| Presentation | No swapchain, no DXGI. All results are offscreen renders read back to the CPU. The native build of vkd3d-proton has the same gap — presentation lives on the Windows/Wine side of the stack. |
| Windows driver | Implements the public Direct3D 12 API as an ordinary Linux library. Not a WDDM driver; does not load into the Windows graphics stack. |

## Hardware budget

Direct3D 12's root signature is a separate ABI, loosely coupled to the shader,
and permits descriptor type aliasing at any heap offset. Root parameters map to
AGX uniform registers at fixed slots, with descriptor tables flattened at bind
time.

| Resource | Budget |
| --- | --- |
| Hardware sampler slots | 1,024, against Direct3D 12's 2,048 |
| Uniform halves | 480 |
| Texture state registers | ~32 |
| Sampler state registers | ~16 |
| Tilebuffer | 64 bytes per sample |

## Relevance to the Windows work

A Direct3D 12 path built on a Vulkan translation layer runs
`D3D12 → vkd3d-proton → Vulkan → Honeykrisp → AGX`. A matured d3d12agx ported to
a Windows user-mode driver would make that `D3D12 → AGX`, removing two
translation steps.

That port has not been started, and no Direct3D 12 support is recorded against
any machine under [feature support](../../feature-support/overview.md).

## Licensing

d3d12agx is MIT, matching Mesa. The vkd3d-proton test suite is LGPL and is used
as a test oracle only — executed, never copied into the tree.
