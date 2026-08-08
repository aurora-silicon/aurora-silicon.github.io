---
title: Testing
---

# Testing

The conformance figures on this site come from the vkd3d-proton Direct3D 12 test
suite, built against d3d12agx. This page is how to reproduce them — including
building the reference implementation so you can compare the two directly.

## Build the test suite against d3d12agx

vkd3d-proton's tests build natively on Linux and link against whichever
Direct3D 12 implementation you point them at. `widl` (from Wine) is required to
generate the headers.

```bash
git clone https://github.com/HansKristian-Work/vkd3d-proton
cd vkd3d-proton
meson setup _agxtest -Denable_tests=true --native-file build-widl.txt
ninja -C _agxtest
```

Point the resulting `d3d12-agx` binary at your built `libd3d12agx.so`, then run
a single test:

```bash
VKD3D_TEST_MATCH=test_draw_instanced ./d3d12-agx
```

`VKD3D_TEST_MATCH` is compared with `strcmp`, so it selects exactly one test.
Verify selection by checking the log contains exactly one begin/end marker pair.

## Build the reference implementation

This is the part that makes the numbers meaningful. vkd3d-proton can build its
*own* Direct3D 12 implementation natively, which then runs on Vulkan via
Honeykrisp — on the same GPU.

```bash
meson setup build-native -Denable_tests=true --native-file build-widl.txt
ninja -C build-native
```

Now the identical test binary can be run two ways:

```bash
# correct behaviour, same GPU:
cd build-native/tests && VKD3D_TEST_MATCH=<test> ./d3d12

# d3d12agx:
cd _agxtest && VKD3D_TEST_MATCH=<test> ./d3d12-agx
```

Diffing those two runs is the single most useful debugging technique available
here. When a test fails with no error message — the driver accepted everything
and produced wrong pixels — there is nothing to grep for, but you can still
watch a known-good implementation do the same work on the same hardware.

## Measurement hygiene

Every one of these rules exists because breaking it produced a wrong result.

**Kill leftovers before every run.**

```bash
pkill -9 -x d3d12-agx; pkill -9 -x d3d12
```

Use `-x` (exact name), never `-f`. A `-f` match will also match the shell
command line containing the string, so a script kills itself. A leftover test
process holds a GPU queue and silently invalidates everything measured after it.

**One GPU job at a time.** Builds and analysis can overlap; GPU runs cannot.

**Redirect to a file, never a pipe.**

```bash
stdbuf -oL -eL env VKD3D_TEST_MATCH=<test> timeout 60 ./d3d12-agx > out.log 2>&1
```

Pipes are block-buffered, so a killed process loses its entire log. This made a
hang look like "no output at all" for hours.

**Judge GPU health by delta, not total.** The cumulative `GPU timeout` count in
`dmesg` never returns to zero without a reboot, so its absolute value says
nothing. Sample it before and after each run and compare.

**A green result is not proof of GPU work.** Many tests never submit anything.
Set `D3D12AGX_DUMP_SYNC=1` and confirm a real submission before concluding
anything about hardware behaviour.

**Never quote a measurement from a build that did not compile.**

## Full suite

Running all 557 tests takes a while and should be done one test per process, each
in its own memory-capped cgroup, so a memory-hungry test fails alone:

```bash
systemd-run --user --scope -p MemoryMax=4G -p MemorySwapMax=0 \
  -- env VKD3D_TEST_MATCH="$t" timeout 25 ./d3d12-agx
```

Without the cap, `test_committed_non_zeroed_behavior_stress` allocates multiple
gigabytes in seconds and can invoke the OOM killer, which on a desktop session
may kill something other than the test.

## What counts as a pass

A test counts only when **every** check in it passes and the kernel journal
shows **0 GPU timeouts, 0 faults, 0 fault reports** across the run. Partial
improvement is recorded but never promoted into the score.
