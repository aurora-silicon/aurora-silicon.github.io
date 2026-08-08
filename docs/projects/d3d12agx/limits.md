---
title: Limits
---

# Limits

What d3d12agx cannot do, separated by *why*. The distinction matters: some of
this is unfinished work, and some of it is the hardware saying no.

## Not implemented yet

<span class="status blocked">Presentation</span>
No swapchain, no DXGI, no way to display a frame. Everything is offscreen render
plus readback. This is the single largest gap between "passes tests" and "runs
software".

Worth noting the native build of vkd3d-proton has the same gap — Direct3D
presentation lives on the Windows/Wine side of the stack, not in the driver.

<span class="status wip">Remaining suite failures</span>
Roughly 34 tests within the reference's pass set are still outstanding. They are
no longer clustered: the largest shared cause covers two tests, so what remains
is a long tail of individually small features plus a set of tests that produce
wrong results with no explicit refusal to point at.

## Blocked by hardware

These cannot be fixed by writing more driver code.

| Feature | Blocker |
| --- | --- |
| 64-bit atomics | AGX has 32-bit atomics and no 64-bit compare-and-swap. The only correct emulation is a per-address spinlock, which serialises access and can deadlock under wave divergence — a robustness trade we have declined to make |
| `GetAttributeAtVertex` (barycentrics) | AGX has no per-vertex fragment inputs. Emulating it means the vertex shader emitting three flat copies of every attribute — a cross-stage ABI change to serve one feature |
| Sparse residency / tile mappings | Not provided by the platform |
| Shared handles | Windows-style cross-process sharing has no equivalent here |
| Sampler feedback | Not supported by the hardware |
| 2048-entry sampler heap | AGX provides 1024 fixed hardware sampler slots; dedup of identical state is the mitigation |

The reference implementation fails these too, which is how we know they are
platform limits rather than our bugs.

## Deliberately declined

Some gaps could be closed but should not be, at least not silently.

The 64-bit atomic emulation above is the clearest case: it is implementable, and
implementing it would raise the test score, but a driver that can deadlock under
divergent access is worse than one that refuses the operation by name. Fixing a
number by fabricating semantics is not a fix.

Where a feature is refused, it is refused explicitly with a diagnostic naming
the reason, rather than silently producing wrong results.

## Shader corpus

Separately from the test suite, a corpus of 334 compiled shaders is used to
track front-end coverage. **321 compile.** The outstanding 13 are:

| Group | Count | Status |
| --- | --- | --- |
| fp64 arithmetic (denorm modes) | 6 | Implementable — AGX has no 64-bit ALU, so this is software lowering. Large, but no blocker |
| 64-bit atomics | 3 | Hardware wall, see above |
| WaveMMA (SM 6.9 cooperative matrix) | 3 | Front-end work, low value |
| `GetAttributeAtVertex` | 1 | Cross-stage ABI wall, see above |

An honest ceiling for the corpus is therefore **327 of 334** without trading
away robustness.
