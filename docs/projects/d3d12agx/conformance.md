---
title: Conformance
---

# Conformance

d3d12agx is measured against the **vkd3d-proton Direct3D 12 test suite** — 557
test functions covering the API surface, shader model behaviour, resource rules
and rendering results. It is the same suite Mesa drivers such as Turnip and NVK
have used as a Direct3D conformance gate.

<div class="scoreboard" markdown>
<div class="cell" markdown><div class="n hero">523</div><div class="l">d3d12agx</div></div>
<div class="cell" markdown><div class="n ref">505</div><div class="l">vkd3d-proton, same GPU</div></div>
<div class="cell" markdown><div class="n">557</div><div class="l">suite total</div></div>
<div class="cell" markdown><div class="n">≥18</div><div class="l">passing that the reference fails</div></div>
</div>

## Why 557 is the wrong denominator

A raw fraction of 557 overstates the work remaining, because some tests cannot
pass on this hardware at all.

To find out which, the identical test binary was built against **vkd3d-proton's
own Direct3D 12 implementation** and run on the same Apple M2, over Vulkan on
the Honeykrisp driver. That is a mature, widely-deployed implementation — it is
what Proton uses to run Direct3D 12 games on Linux today.

It scores **505 of 557**.

The 52 it misses are dominated by things the platform does not provide: sparse
residency and tile mappings, Windows-style shared handles, sampler feedback,
raytracing acceleration-structure validation, and a few memory-bound stress
tests. Those are not d3d12agx bugs and chasing them would be wasted effort.

So the meaningful reference point is 505, not 557.

## Passing tests the reference fails

d3d12agx currently scores **523**, which is 18 above the reference. Since the
reference's pass set contains only 505 tests, **at least 18 of our passes must
lie outside it** — that follows from the arithmetic alone.

When this was last measured exactly, at a score of 471, the figure was **25
tests** passing here that vkd3d-proton fails on identical hardware.

This is not a claim that d3d12agx is a better driver. It is a consequence of
removing a layer. Direct3D 12 → Vulkan is a lossy mapping, and several D3D12
behaviours have no faithful Vulkan expression:

| Area | Why the translation loses it |
| --- | --- |
| Texture array view reinterpretation | D3D12 permits casts that Vulkan's image-view rules forbid |
| Structured / raw / typed view aliasing | D3D12 allows aliasing at one heap offset; SPIR-V descriptor types do not |
| Null descriptor behaviour | D3D12 defines reads through a null descriptor; Vulkan's equivalent is narrower |
| Typed buffer object counts | Vulkan descriptor-count limits |

Compiling DXIL straight to NIR skips that bottleneck entirely.

## How a pass is counted

The campaign's rule is that a number must be reproducible by someone else, so
the measurement protocol is deliberately strict:

1. **Exact selection.** `VKD3D_TEST_MATCH` is compared with `strcmp` in the
   vkd3d harness, so one target runs per process. Selection is proven by exactly
   one begin/end marker pair in the log.
2. **One target at a time**, each in its own memory-capped cgroup (4 GiB, swap
   disabled) so a memory-hungry test fails alone rather than taking the machine
   with it.
3. **Process hygiene.** Every run is preceded by an exact-name kill of any
   leftover test process. A stale process holds a GPU queue and silently
   invalidates everything measured after it.
4. **Whole-test passes only.** A test counts when every one of its checks
   passes. Partial improvement is not promoted into the score.
5. **Kernel delta must be clean.** Each run records the kernel journal before
   and after and must show exactly **0 GPU timeouts, 0 GPU faults, 0 fault
   reports**. A pass that disturbed the GPU is not a pass.
6. **Logs are retained** per test, dated, never overwritten.

!!! warning "Things that have invalidated measurements here"

    Each of these produced a wrong conclusion at least once before becoming a rule:

    - **A wedged GPU invalidates interactive measurement.** The cumulative
      `GPU timeout` count in `dmesg` never returns to zero without a reboot, so
      it says nothing about current health. Only the delta across a single run
      is meaningful.
    - **Instrumented runs are not evidence.** A census taken with GPU submission
      gated off shows every render as blank. Those logs cannot support any claim
      about rendering behaviour.
    - **A test can "pass" without touching the GPU.** Unless a submission is
      observed, a green result may mean the work was never dispatched.

## Reproducing it

The suite, the runner and the per-test logs are all in the repository. See
[Testing](../../developers/testing.md) for the exact commands, including how to
build the reference implementation and run the same binary against both.

## Caveats worth stating

- **This is not WHQL or any certified conformance programme.** It is one
  open-source test suite, chosen because it is the strictest Direct3D 12 test
  corpus that can be run on Linux.
- **Passing the suite is not the same as running applications.** With no
  presentation layer, d3d12agx cannot yet run a real program end to end.
- **The score moves.** These figures were current at the time of writing; the
  repository is the authority.
