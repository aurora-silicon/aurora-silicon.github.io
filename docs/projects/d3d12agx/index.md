---
title: d3d12agx
---

# d3d12agx — DirectX 12 on the Apple GPU

!!! info "Research project, on Linux"

    d3d12agx is an **experiment**, separate from the Windows stack. It runs on
    Linux, has no presentation layer, and is not part of how Aurora Silicon
    renders on Windows today — that is [Honeykrisp with DXVK and
    vkd3d-proton](../gpu.md).

    Its purpose is to test whether Direct3D 12 can be implemented directly on
    Apple's GPU, with no Vulkan layer in between. The answer is yes: 553 of 557
    conformance tests pass, with four classified failures remaining.

d3d12agx is a **Direct3D 12 user-mode driver** for Apple's AGX GPU, written from
scratch on the Mesa/Asahi substrate.

Direct3D shader bytecode — both DXIL (Shader Model 6) and DXBC (Shader Model 5)
— is compiled straight to AGX machine code. There is no Vulkan layer, no SPIR-V,
and no runtime dependency on Microsoft's shader compiler.

<div class="scoreboard" markdown>
<div class="cell" markdown><div class="n hero">553</div><div class="l">tests passing</div></div>
<div class="cell" markdown><div class="n ref">505</div><div class="l">vkd3d-proton, same GPU</div></div>
<div class="cell" markdown><div class="n">~39k</div><div class="l">lines of C</div></div>
<div class="cell" markdown><div class="n">0</div><div class="l">translation layers</div></div>
</div>

## Why it matters to the Windows work

Today Direct3D 12 on Aurora Silicon goes
`D3D12 → vkd3d-proton → Vulkan → Honeykrisp → AGX`. That works, and it is what
ships.

If d3d12agx matures and is ported to a Windows user-mode driver, that chain
becomes `D3D12 → AGX`. Two translation steps removed, and — measurably — some
Direct3D 12 behaviour becomes expressible that a Vulkan layer cannot represent
at all.

That port has not been started. This is a research result, not a roadmap item
with a date.

## What kind of thing is this?

Every graphics driver has two halves. The **kernel-mode driver** owns the
hardware — memory, scheduling, fault handling. On Apple Silicon under Linux that
is `drm/asahi`, written by the Asahi Linux project; we use it as-is.

The **user-mode driver** is everything above: the API an application calls,
compiling its shaders to machine code, and building the command streams the GPU
executes. That half is what d3d12agx is.

So it is the same class of software as RADV (Vulkan on AMD) or Honeykrisp
(Vulkan on AGX) — for a different API.

!!! info "It is not a translation layer"

    vkd3d-proton and DXVK take Direct3D calls and re-emit them as Vulkan; they
    need a Vulkan driver underneath. d3d12agx emits AGX machine code and submits
    it to the kernel directly. Nothing sits between it and the GPU.

    Mesa also contains a driver called `d3d12`, but it runs the other direction
    — OpenGL and OpenCL implemented *on top of* Direct3D 12 on Windows. This is
    the opposite: Direct3D 12 implemented on top of hardware.

## What works

Every graphics stage that replaces fixed-function hardware executes on real
silicon, verified pixel-exact against CPU reference rasterisation:

- **Vertex** — including vertex buffers, interleaved attributes, indexed draws
  with non-zero base vertex and start index, and instancing
- **Geometry** — lowered to compute dispatches ordered ahead of the render pass
- **Tessellation** — hull and domain stages, via a compute-based tessellator
- **Mesh and amplification** — with no Honeykrisp counterpart to reference;
  Honeykrisp implements no mesh shaders at all
- **Pixel** — including multisampling, interpolation modes and coverage

Alongside: multiple render targets, blending, depth and stencil, queries,
indirect execution, stream output, bindless resource and sampler heaps, and
GPU-readable descriptor storage.

## What does not work

<span class="status blocked">No presentation</span> There is no swapchain and no
DXGI. The driver renders correctly but cannot put a pixel in a window. Every
result to date is an offscreen render read back to the CPU and compared.

This is worth putting in context: the native build of vkd3d-proton cannot
present either. DXGI lives on the Windows/Wine side of the stack, so this is a
gap in the category rather than a gap against the reference.

<span class="status none">Not a Windows driver</span> d3d12agx implements the
public Direct3D 12 API as an ordinary Linux library. It is not a WDDM driver and
does not load into the Windows graphics stack.

Remaining known gaps are catalogued in [Limits](limits.md).

## Reading further

- **[Conformance](conformance.md)** — the numbers, how they were measured, and
  what the reference comparison does and does not prove
- **[Architecture](architecture.md)** — the stack, the shader path, the binding
  model
- **[Limits](limits.md)** — what is unreachable on this hardware and why
- **[Building](../../developers/building.md)** — build it and reproduce the
  figures yourself
