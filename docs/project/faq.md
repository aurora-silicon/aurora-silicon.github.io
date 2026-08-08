---
title: FAQ
---

# Frequently asked questions

## Can I play games with this yet?

No. d3d12agx has no presentation layer — it renders correctly but cannot display
a frame to a window, so it cannot run an application end to end.

For actually playing Direct3D 12 games on Apple Silicon today, use Proton with
vkd3d-proton on Honeykrisp. That works now and is the right answer.

## Then what is the point?

Two things.

The conformance result is evidence that Direct3D 12 can be implemented directly
on Apple's GPU without a translation layer — including passing tests the
Vulkan-based route cannot, because some D3D12 semantics have no faithful Vulkan
expression.

And it is the graphics half of running Windows on Apple Silicon, where there is
no Vulkan driver to translate to in the first place.

## Is this faster than vkd3d-proton?

Unknown — no performance comparison has been run, and it would be premature. The
work so far has been entirely about correctness. Removing a translation layer
*should* reduce CPU overhead, but "should" is not a benchmark, and vkd3d-proton
is mature and heavily optimised.

Anyone quoting a performance number for d3d12agx today is guessing.

## How can it beat vkd3d-proton if it is so much newer?

It does not beat it overall. It passes more of one test suite on one GPU.

The reason is structural rather than a matter of quality: Direct3D 12 → Vulkan
loses information. Texture array view reinterpretation, structured/raw/typed
view aliasing and null-descriptor behaviour are all defined in D3D12 in ways
Vulkan's rules cannot express, so those tests are unwinnable through a Vulkan
layer no matter how good the implementation is.

## Does this work on my Mac?

If it is an M1 or M2 family machine running Asahi Linux, probably — but only the
base M2 has actually been tested. M3 and later are not supported, because the
underlying Mesa AGX substrate does not support them yet. See
[Hardware support](../platform/support.md).

## Is this affiliated with Asahi Linux?

No. Aurora Silicon is a separate, unaffiliated project.

We build on Asahi's kernel, the `drm/asahi` GPU driver and Mesa's AGX compiler
infrastructure, and none of this would exist without that work. But please
report our bugs to us, not to them.

## Will this be upstreamed to Mesa?

Not currently planned. It is a large driver for an API Mesa does not otherwise
implement in this direction, and upstreaming would need buy-in we have not
sought. The code is MIT and public regardless, so anyone can use it.

## Why not use dxil-spirv?

Because it emits SPIR-V, and SPIR-V requires structured control flow. DXIL does
not have it, so translating DXIL → SPIR-V means reconstructing structure from an
arbitrary control-flow graph — the hardest problem in that space.

NIR has no such requirement, so going straight to NIR avoids the problem rather
than solving it. dxil-spirv is MIT licensed, so this was an engineering choice,
not a licensing one.

## What about macOS or Windows?

macOS is out of scope; Apple's own driver owns the GPU there.

Windows would require porting d3d12agx to a WDDM user-mode driver and pairing it
with a kernel-mode driver. That is the long-term point of the exercise, but it
has not been started.
