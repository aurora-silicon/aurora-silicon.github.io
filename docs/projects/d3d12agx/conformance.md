---
title: Conformance
---

# Conformance

d3d12agx is measured against the **vkd3d-proton Direct3D 12 test suite** — 557
test functions covering the API surface, shader model behaviour, resource rules
and rendering results. It is the same suite Mesa drivers such as Turnip and NVK
have used as a Direct3D conformance gate.

<div class="scoreboard" markdown>
<div class="cell" markdown><div class="n hero">553</div><div class="l">d3d12agx</div></div>
<div class="cell" markdown><div class="n ref">505</div><div class="l">vkd3d-proton, same GPU</div></div>
<div class="cell" markdown><div class="n">557</div><div class="l">suite total</div></div>
<div class="cell" markdown><div class="n">+48</div><div class="l">passing that the reference fails</div></div>
</div>

## The reference, and why it is not a ceiling

The identical test binary was built against **vkd3d-proton's own Direct3D 12
implementation** and run on the same Apple M2, over Vulkan on Honeykrisp. That
is a mature, widely-deployed implementation — it is what Proton uses to run
Direct3D 12 games on Linux today.

It scores **505 of 557**. d3d12agx scores **553**.

For a long time the 52 tests the reference misses were treated as
platform-impossible, and the campaign planned around 505 as a ceiling. **That
was wrong, and the error is worth recording**: an audit showed 25 of those 52
were already passing here, so the group was never impossible. Everything since
came from re-testing rows that had been written off because the comparator
failed them.

Two that were explicitly documented as hardware walls on this site have since
been implemented:

| Was called a wall | What it actually needed |
| --- | --- |
| 2,048-entry sampler heap vs AGX's 1,024 slots | Sampler-state virtualization |
| Sparse residency and tile mappings | Full Tier-1 tiled resources |

The lesson generalises: **a comparator failing a test means nobody had done it,
not that it could not be done.**

## What actually remains

Four tests, each with a named cause rather than an assumption:

| Test | Cause |
| --- | --- |
| `test_open_heap_from_address` | Requires an Asahi **kernel** user-memory import ABI that does not exist. Not a driver gap |
| Two structured/raw typed-read probes | Vendor-**undefined** behaviour. Excluded rather than fabricated — passing them would mean inventing semantics |
| `test_stress_fallback_render_target_allocation_device` | Requests roughly 16 GiB on a 7.3 GiB machine. Truthful support needs a residency/eviction architecture |

Two of those four are arguably not scoreable at all, and one is a property of
the machine rather than the driver.

## Head-to-head on the same GPU

Conformance says both implementations are correct. The obvious next question is
what each costs.

`d3d12agx/bench/duel.sh` runs the identical workload against both libraries —
one binary, `dlopen`-ing either — and byte-compares the resulting images before
reporting any timing, because a speed comparison between two stacks that drew
different things is meaningless.

1,000 frames, 256×256, clear + draw + fence wait:

| | d3d12agx | vkd3d-proton |
| --- | --- | --- |
| mean | 0.181 ms | **0.171 ms** |
| median | 0.160 ms | **0.146 ms** |
| p99 | 0.841 ms | **0.769 ms** |
| images | \multicolumn | **byte-identical** |

**vkd3d-proton is ~1.06x faster on this workload.** Removing a translation
layer has not yet produced a speed win — and it is worth saying so plainly
rather than quietly not measuring it.

!!! warning "This is not a graphics benchmark"

    A 3-vertex triangle at 256×256 is nothing for this GPU, so what is being
    measured is the CPU cost of recording and submitting a frame plus the round
    trip to completion — not shader throughput, not fill rate, not anything an
    application would notice. Do not quote it as a general performance figure.

    It is useful for exactly one thing: showing that the submission path is in
    the same order of magnitude as a mature implementation, and where the tail
    latency sits.

### An interop hazard found while building it

`GetCPUDescriptorHandleForHeapStart` returns a struct by value, and the two
implementations disagree on how. d3d12agx returns it plainly; vkd3d-proton uses
widl's `WIDL_EXPLICIT_AGGREGATE_RETURNS` convention, where the caller passes a
hidden result pointer.

Each is self-consistent with the headers it was built against. But **a single
process calling both through one set of header macros will corrupt memory** —
it passes nothing in the hidden-pointer register for one of them. The benchmark
selects the convention at runtime. Anyone binding these two implementations
into one binary needs to know this.

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
