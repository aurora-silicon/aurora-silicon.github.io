---
title: Glossary
---

# Glossary

Terms used across this site, in the sense we use them.

## Graphics

**AGX**
: Apple's GPU architecture, used across the M-series. Undocumented publicly;
  everything known about it comes from reverse engineering.

**Direct3D 12 / D3D12**
: Microsoft's low-level graphics API. Applications manage memory, synchronisation
  and command recording explicitly.

**DXBC**
: The Direct3D shader bytecode container for Shader Model 5 and earlier. A
  token-based instruction stream with signatures in separate chunks.

**DXIL**
: The Direct3D shader container for Shader Model 6. LLVM 3.7-era bitcode with
  Direct3D conventions layered on — resources and signatures in metadata,
  operations as `dx.op` intrinsic calls.

**NIR**
: Mesa's shader intermediate representation. Every Mesa driver compiles through
  it, which is why targeting NIR gives access to the existing AGX backend.

**SPIR-V**
: Khronos' shader IR, used by Vulkan. Requires structured control flow — the
  reason d3d12agx does not route through it.

**UMD / KMD**
: User-mode driver and kernel-mode driver, the two halves of a graphics driver.
  The UMD compiles shaders and builds command streams; the KMD owns the hardware.

**Honeykrisp**
: Mesa's Vulkan driver for AGX. A sibling to d3d12agx, not a dependency — and
  our correctness reference for how to program the hardware.

**vkd3d-proton**
: A Direct3D 12 → Vulkan translation layer, used by Proton to run D3D12 games on
  Linux. Here it serves as both test suite and reference implementation.

**Root signature**
: Direct3D 12's description of what resources a shader can access. A separate ABI
  from the shader itself, which is why bindings cannot be inferred from shader
  code alone.

**Tilebuffer**
: On-chip memory holding the pixels of one tile during rendering. Its size bounds
  how many render targets can be live before spilling to memory.

**USC / VDM / CDM**
: AGX hardware units. USC words configure shader execution; VDM and CDM are the
  vertex/render and compute command streams the GPU consumes.

**ail**
: Mesa's AGX image layout library — computes tiling, strides and offsets for
  textures.

## Platform

**AIC2**
: Apple's interrupt controller, second generation. Not a GIC, which is what
  Windows on ARM expects, hence the native HAL extension.

**DART**
: Apple's IOMMU, sitting in front of most peripherals.

**m1n1**
: The Asahi bootloader and experimentation tool. Its hypervisor mode traces guest
  hardware access against real silicon.

**Project Mu**
: Microsoft's UEFI implementation, used here to provide firmware and ACPI tables
  for Windows.

**HAL extension**
: A Windows driver supplying platform-specific behaviour to the hardware
  abstraction layer — how a native AIC2 interrupt path is provided without
  emulating a GIC.

**WDDM**
: The Windows Display Driver Model. A Windows GPU driver must implement it;
  d3d12agx currently implements the public D3D12 API instead.

**j316s**
: Apple's internal model code for the 16-inch MacBook Pro with M1 Pro — the
  primary Windows bring-up target.

## Measurement

**Oracle**
: A known-good implementation used to decide what correct behaviour is. Here,
  vkd3d-proton running on the same GPU.

**Reachable ceiling**
: The highest score any correct implementation can reach on this hardware,
  measured rather than assumed — 505 of 557 for the D3D12 suite.

**Kernel delta**
: The change in GPU timeout and fault counts across a single test run. A pass
  requires zero.

**Whole-test pass**
: Every check in a test passes. Partial improvement is recorded but never counted.
