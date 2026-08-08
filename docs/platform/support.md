---
title: Hardware Support
---

# Hardware support

What runs where. Status is deliberately conservative: a machine is only marked
tested if the work has actually been run on it.

| | |
| --- | --- |
| <span class="status works">Tested</span> | Verified on this hardware |
| <span class="status partial">Expected</span> | Should work — same GPU generation, no known blocker, but not yet run |
| <span class="status wip">In progress</span> | Actively being worked on |
| <span class="status none">Unsupported</span> | Not supported today |

## d3d12agx

The driver reads the GPU generation at runtime and hardcodes nothing about a
specific chip, so support follows whatever the Mesa AGX substrate supports.

| Chip | GPU | Status | Notes |
| --- | --- | --- | --- |
| M2 | G14G | <span class="status works">Tested</span> | All figures on this site were measured here |
| M1 | G13G | <span class="status partial">Expected</span> | Recognised by the substrate; not yet run |
| M1 Pro / Max / Ultra | G13X | <span class="status partial">Expected</span> | Recognised; not yet run |
| M2 Pro / Max / Ultra | G14X | <span class="status partial">Expected</span> | Recognised; not yet run |
| M3 and later | AGX2 / G15+ | <span class="status none">Unsupported</span> | Not yet supported by the underlying Mesa AGX substrate |

!!! note "Why 'expected' rather than 'supported'"

    The chip is detected at runtime and threaded through the command-stream
    encoders, and nothing in the driver assumes a specific part. That is an
    architectural expectation, not a measurement. Tilebuffer sizing and
    multi-die parts are the most likely places for a surprise.

    If you run the suite on an M1-family machine, we would like the results.

**Operating system:** Linux only. The driver speaks DRM ioctls to `drm/asahi`.
macOS is out of scope — Apple's own driver owns the GPU there. Windows would
require a WDDM port that does not exist yet.

## Windows on Apple Silicon

| Machine | Status | Notes |
| --- | --- | --- |
| MacBook Pro 16" (M1 Pro, j316s) | <span class="status wip">In progress</span> | Primary development target — boot chain, AIC2 HAL extension, peripherals |
| Other Apple Silicon Macs | <span class="status none">Unsupported</span> | Each machine needs its own hardware description; nothing is generic yet |

Windows bring-up is far more machine-specific than the GPU work. Device trees,
ACPI tables and peripheral addresses differ per model, so support does not
generalise from one machine to another without work.

## Requirements

For d3d12agx:

- An Apple Silicon Mac running **Asahi Linux** (or another distribution with the
  Asahi kernel)
- A kernel whose `drm/asahi` UAPI matches the Mesa version being built
- **DirectX-Headers 1.619.1** installed system-wide — the tests include
  `<directx/d3d12.h>` and `<wsl/winadapter.h>` directly

Full build instructions are in [Building](../developers/building.md).
