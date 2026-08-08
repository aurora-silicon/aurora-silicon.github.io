---
title: Architecture
---

# Architecture

## The stack

```
        Direct3D 12 application
                  │
                  ▼
        ┌──────────────────────┐
        │      d3d12agx        │   ID3D12Device, command lists,
        │  (user-mode driver)  │   resources, descriptors, PSOs
        └──────────────────────┘
                  │
        DXIL / DXBC → NIR → AGX
                  │
                  ▼
        ┌──────────────────────┐
        │  Mesa AGX substrate  │   compiler backend, ail layout,
        │  (shared with Mesa)  │   genxml packing, libagx
        └──────────────────────┘
                  │
              DRM ioctls
                  ▼
        ┌──────────────────────┐
        │      drm/asahi       │   kernel-mode driver
        └──────────────────────┘
                  │
                 AGX
```

Nothing in that path is a translation layer. The driver produces AGX machine
code and command streams, and submits them to the kernel.

!!! note "Relationship to Honeykrisp"

    Honeykrisp is Mesa's Vulkan driver for AGX. d3d12agx does **not** run on top
    of it — they are siblings sharing the same lower layers. Honeykrisp is used
    as a *correctness reference*: when the two drivers program the same hardware
    differently, Honeykrisp is presumed right and the divergence is investigated.

## Components

| Component | Responsibility |
| --- | --- |
| `d12_device.c` | `ID3D12Device`, adapter and feature queries, view creation |
| `d12_cmd.c` | Command lists, draws, dispatches, USC and PPP encoding |
| `d12_queue.c` | Submission, fences on DRM syncobj timelines |
| `d12_resource.c` | Resource creation, `ail` layout selection |
| `d12_descriptor.c` | Descriptor heaps |
| `d12_pipeline.c` | Pipeline state compilation, prolog/epilog linking |
| `d12_root_sig.c` | Root signature serialise and parse (RTS0) |
| `d12_format.c` | DXGI ↔ pipe format mapping |
| `dxil/` | Shader bytecode front end — container, bitstream, module, translation |

## The shader path

Direct3D ships shaders in two container formats, and d3d12agx reads both.

**DXIL** (Shader Model 6) is LLVM 3.7-era bitcode with Direct3D conventions
layered on: resources, entry points and I/O signatures live in LLVM metadata,
and operations are expressed as calls to `dx.op` intrinsics. The front end
parses the container, decodes the bitstream, reconstructs the module, then
lowers `dx.op` calls to NIR.

**DXBC** (Shader Model 5) is a different, older container with a token-based
instruction stream and its input signature in a separate `ISGN` chunk.

Both converge on **NIR**, Mesa's shader intermediate representation, and from
there through Mesa's existing AGX backend to machine code.

### Why no SPIR-V

The obvious shortcut would be DXIL → SPIR-V (via the existing dxil-spirv
project) → NIR. It was rejected deliberately.

SPIR-V requires **structured control flow**. DXIL does not have it, so any
DXIL → SPIR-V translator must reconstruct structure from an arbitrary control
flow graph — a problem its most experienced implementer has publicly described
as among the hardest they have worked on.

NIR imposes no such requirement. Going directly to NIR does not solve CFG
structurisation; it avoids ever having the problem.

## Binding model

Direct3D 12's root signature is a separate ABI, only loosely coupled to the
shader. Bindings cannot be derived from shader code alone, and the API permits
descriptor type aliasing at any heap offset.

d3d12agx maps root parameters into AGX uniform registers at fixed slots, with
descriptor tables flattened at bind time and a GPU-readable descriptor heap for
bindless access. Sampler state uses AGX's separate sampler heap.

The hardware constrains this in ways worth knowing:

- **1024 hardware sampler slots**, against Direct3D 12's promised 2048.
  Deduplication of identical sampler state is required to stay inside it.
- **480 uniform halves**, ~32 texture state registers and ~16 sampler state
  registers form the real root-signature budget.
- **64 bytes per sample of tilebuffer**, which bounds how many render targets
  can be live before spilling.

## Licensing

d3d12agx is **MIT**, matching Mesa.

The vkd3d-proton test suite is LGPL. It is used as a test oracle and reference
only — it is executed, never copied into this tree. No code from it appears in
d3d12agx.
