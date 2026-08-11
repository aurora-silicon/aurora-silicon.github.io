---
title: Feature Support
---

# Feature support

Aurora Silicon tracks machines and features separately. A machine in the lab is
not automatically supported, and support on one member of a chip family does
not imply support on its siblings. This page follows the generation-first shape
of the [Asahi Linux feature-support overview](https://asahilinux.org/docs/platform/feature-support/overview/),
but every state below describes **Aurora Silicon's Windows bring-up only**.

<div class="support-legend">
  <span><span class="status works">Tested</span> validated on this exact hardware</span>
  <span><span class="status partial">Partial</span> boots with known gaps</span>
  <span><span class="status wip">Preliminary</span> active bring-up</span>
  <span><span class="status none">Not tested</span> catalogued, no hardware proof</span>
</div>

<div class="family-grid">
  <a class="family-card" href="support/m1/"><strong>M1 series</strong><span>M1 · Pro · Max · Ultra</span><small>6 model families</small></a>
  <a class="family-card" href="support/m2/"><strong>M2 series</strong><span>M2 · Pro · Max · Ultra</span><small>6 model families</small></a>
  <a class="family-card" href="support/m3/"><strong>M3 series</strong><span>M3 · Pro · Max · Ultra</span><small>5 model families</small></a>
  <a class="family-card" href="support/m4/"><strong>M4 series</strong><span>M4 · Pro · Max</span><small>5 model families</small></a>
  <a class="family-card family-card--active" href="support/m5/"><strong>M5 series</strong><span>M5 · Pro · Max</span><small>Active Air bring-up</small></a>
  <a class="family-card" href="support/a18/"><strong>A18 series</strong><span>MacBook Neo</span><small>Lab hardware</small></a>
</div>

!!! warning "Support does not generalise across machines"

    Device trees, ACPI tables, peripheral addresses and firmware profiles vary
    by model. Each target needs its own launch contract and firmware manifest.
    Owner badges mean we can test that hardware; they are not support claims.

<span id="devices-owned-by-us"></span>

## Apple Silicon model catalog

The catalog is grouped by SoC generation instead of presenting a second support
table. Owner badges mark machines currently available to the Aurora Silicon
team. Multiple screen sizes and chip bins are combined when they share a model
family.

### [M1 generation](support/m1.md)

<div class="device-grid">
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Air 13-inch</h3><span class="status none">Not tested</span></div>
    <p>M1 · 2020</p><div class="device-card__chips"><span class="owner-badge">Owned · Ace</span></div>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Pro 13-inch</h3><span class="status none">Not tested</span></div>
    <p>M1 · 2020</p>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>Mac mini</h3><span class="status none">Not tested</span></div>
    <p>M1 · 2020</p>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>iMac 24-inch</h3><span class="status none">Not tested</span></div>
    <p>M1 · 2021</p><div class="device-card__chips"><span class="owner-badge">Owned · Liam</span></div>
  </article>
  <article class="device-card is-partial">
    <div class="device-card__top"><h3>MacBook Pro 14 / 16-inch</h3><span class="status partial">Partial</span></div>
    <p>M1 Pro / M1 Max · 2021 · <code>j316s</code> evidence</p>
    <div class="device-card__chips"><span class="owner-badge">Owned · Ryan</span></div>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>Mac Studio</h3><span class="status none">Not tested</span></div>
    <p>M1 Max / M1 Ultra · 2022</p>
  </article>
</div>

### [M2 generation](support/m2.md)

<div class="device-grid">
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Air 13 / 15-inch</h3><span class="status none">Not tested</span></div>
    <p>M2 · 2022–2023</p><div class="device-card__chips"><span class="owner-badge">Owned · Ryan</span></div>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Pro 13-inch</h3><span class="status none">Not tested</span></div>
    <p>M2 · 2022</p>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>Mac mini</h3><span class="status none">Not tested</span></div>
    <p>M2 / M2 Pro · 2023</p>
  </article>
  <article class="device-card is-tested">
    <div class="device-card__top"><h3>MacBook Pro 14 / 16-inch</h3><span class="status works">Tested</span></div>
    <p>M2 Pro / M2 Max · 2023 · <code>j414s</code> primary target</p>
    <div class="device-card__chips"><span class="owner-badge">Owned · DJ</span></div>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>Mac Studio</h3><span class="status none">Not tested</span></div>
    <p>M2 Max / M2 Ultra · 2023</p>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>Mac Pro</h3><span class="status none">Not tested</span></div>
    <p>M2 Ultra · 2023</p>
  </article>
</div>

### [M3 generation](support/m3.md)

<div class="device-grid">
  <article class="device-card">
    <div class="device-card__top"><h3>iMac 24-inch</h3><span class="status none">Not tested</span></div>
    <p>M3 · 2023</p>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Pro 14-inch</h3><span class="status none">Not tested</span></div>
    <p>M3 · 2023</p>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Pro 14 / 16-inch</h3><span class="status none">Not tested</span></div>
    <p>M3 Pro / M3 Max · 2023</p><div class="device-card__chips"><span class="owner-badge">M3 Max · Owned · Ace</span></div>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Air 13 / 15-inch</h3><span class="status none">Not tested</span></div>
    <p>M3 · 2024</p>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>Mac Studio</h3><span class="status none">Not tested</span></div>
    <p>M3 Ultra · 2025</p>
  </article>
</div>

### [M4 generation](support/m4.md)

<div class="device-grid">
  <article class="device-card">
    <div class="device-card__top"><h3>iMac 24-inch</h3><span class="status none">Not tested</span></div>
    <p>M4 · 2024</p>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>Mac mini</h3><span class="status none">Not tested</span></div>
    <p>M4 / M4 Pro · 2024</p>
    <div class="device-card__chips"><span class="owner-badge">Owned · Ace</span><span class="owner-badge">Owned · Liam</span></div>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Pro 14 / 16-inch</h3><span class="status none">Not tested</span></div>
    <p>M4 / M4 Pro / M4 Max · 2024</p>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Air 13 / 15-inch</h3><span class="status none">Not tested</span></div>
    <p>M4 · 2025</p><div class="device-card__chips"><span class="owner-badge">Owned · Liam</span></div>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>Mac Studio</h3><span class="status none">Not tested</span></div>
    <p>M4 Max · 2025</p>
  </article>
</div>

### [M5 generation](support/m5.md)

<div class="device-grid">
  <article class="device-card is-preliminary">
    <div class="device-card__top"><h3>MacBook Air 13 / 15-inch</h3><span class="status wip">Preliminary</span></div>
    <p>M5 · T8142 · <code>j813</code> active bring-up</p>
    <div class="device-card__chips"><span class="owner-badge">Owned · Ace</span></div>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Pro 14-inch</h3><span class="status none">Not tested</span></div>
    <p>M5</p><div class="device-card__chips"><span class="owner-badge">Owned · Liam</span></div>
  </article>
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Pro 14 / 16-inch</h3><span class="status none">Not tested</span></div>
    <p>M5 Pro / M5 Max</p><div class="device-card__chips"><span class="owner-badge">M5 Pro · Owned · DJ</span></div>
  </article>
</div>

### [A-series Mac](support/a18.md)

<div class="device-grid">
  <article class="device-card">
    <div class="device-card__top"><h3>MacBook Neo</h3><span class="status none">Not tested</span></div>
    <p>A18 · 8 GB memory · 256 GB storage</p>
    <div class="device-card__chips"><span class="owner-badge">Owned · Ace</span></div>
  </article>
</div>

## Windows feature matrix

This matrix contains the targets with actual Aurora Silicon evidence. A dash in
the catalog does not become a support claim here until that exact machine is
tested.

<div class="feature-matrix-wrap" markdown>

| Feature | M2 Pro MacBook Pro `j414s` | M1 Pro MacBook Pro `j316s` | M5 MacBook Air `j813` |
| --- | --- | --- | --- |
| m1n1 boot / proxy | <span class="status works">Working</span> | <span class="status works">Working</span> | <span class="status works">Working</span> |
| Project Mu / UEFI | <span class="status works">Working</span> | <span class="status partial">Partial</span> | <span class="status works">Working</span> |
| CPU topology / SMP | <span class="status wip">In progress</span> | <span class="status wip">In progress</span> | <span class="status partial">Partial</span> — 10 cores described |
| Internal storage | <span class="status works">Working</span> | <span class="status partial">Partial</span> | <span class="status partial">Read only</span> — 4 KiB block I/O |
| GPT partition map | <span class="status works">Working</span> | <span class="status partial">Partial</span> | <span class="status works">Working</span> — CRC verified |
| Windows boot | <span class="status works">Desktop</span> | <span class="status partial">WinPE</span> | <span class="status partial">Setup launches</span> |
| Internal display | <span class="status works">Working</span> | <span class="status partial">Partial</span> | <span class="status works">UEFI framebuffer</span> |
| Built-in keyboard / trackpad | <span class="status partial">Partial</span> | <span class="status partial">Partial</span> | <span class="status wip">In progress</span> |
| USB | <span class="status partial">Partial</span> | <span class="status partial">Partial</span> | <span class="status partial">Partial</span> |
| GPU acceleration | <span class="status works">Vulkan + D3D11</span> | <span class="status partial">Partial</span> | <span class="status none">Unsupported</span> |
| Audio | <span class="status partial">Partial</span> | <span class="status none">Unsupported</span> | <span class="status none">Unsupported</span> |
| Wi-Fi / Bluetooth | <span class="status wip">In progress</span> | <span class="status none">Unsupported</span> | <span class="status none">Unsupported</span> |

</div>

### Target notes

**M2 Pro is the most validated target.** It is where booting from internal
storage, the native AIC2 interrupt path, Vulkan 1.4.354, Direct3D 11 feature
level 11.0 and physical-console presentation were proven.

**M5 MacBook Air is an engineering target, not a usable Windows installation.**
Its internal ANS/NVMe path is intentionally read-only. GPT discovery and an
unmodified ARM64 Windows Setup launch are proven; installation, input and full
secondary-core behaviour remain incomplete.

## d3d12agx (Linux)

The [d3d12agx](../projects/d3d12agx/index.md) research driver is separate and
runs on Linux, not Windows.

| Chip | GPU | Status |
| --- | --- | --- |
| M2 | G14G | <span class="status works">Tested</span> |
| M1, M1 Pro/Max/Ultra, M2 Pro/Max/Ultra | G13G / G13X / G14X | <span class="status partial">Expected</span> — recognised by the substrate, not run |
| M3 and later | AGX2 | <span class="status none">Unsupported</span> — not yet supported by the Mesa AGX substrate |

## Requirements

Windows bring-up needs a host machine for tethered boot and debugging, an m1n1
build matching the target, Project Mu firmware artifacts for that target, and a
test-signing setup. HAL-extension signing needs certificates that are not
distributed here.

Nothing here is a supported installation path. Expect breakage, and do not use a
machine whose data matters.
