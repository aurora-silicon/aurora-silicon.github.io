---
title: Feature Support
---

# Feature Support

Apple sells one marketing name across several different chips, and puts one chip
in several different machines. Support has to be tracked per machine, so this
section is organised the way the hardware actually is rather than the way it is
advertised.

The catalog contains **59 board configurations**, grouped by generation and product. Device dialogs show **Windows** results. The [Aurora Linux evidence directory](linux/overview.md) contains separate, dated Linux implementation assessments and hardware reports for the same boards.

## How Apple hardware is identified

Three names matter, and they don't map one to one.

| Name | Looks like | What it identifies |
| --- | --- | --- |
| Marketing name | M1 Pro, M4, A18 Pro | What Apple sells the chip as |
| SoC ID | `t6000` | The chip itself |
| Device ID | `j316s` | One specific machine |

A 16-inch MacBook Pro from 2021 is device `j316s`, its chip is `t6000`, and Apple
calls that chip the M1 Pro. The 14-inch model from the same launch is a different
machine, `j314s`, running the same chip. The two share silicon but not an
enclosure, a display, or a set of peripherals — so they are catalogued
separately.

Device IDs sometimes carry a suffix that distinguishes chip bins within one
enclosure: `j314s` is the M1 Pro 14-inch, `j314c` the M1 Max version of the same
laptop. Where Apple shipped two configurations that differ in ways the firmware
can see — port count on the iMac, core count on the M3 Max — each gets its own
device ID.

## Generations

<div class="gen-grid">
  <a class="gen-card" href="/feature-support/m1/">
    <span class="gen-card__name">M1 series</span>
    <span class="gen-card__socs"><span class="soc-id">t8103</span><span class="soc-id">t6000</span><span class="soc-id">t6001</span><span class="soc-id">t6002</span></span>
    <span class="gen-card__count">11 machines</span>
  </a>
  <a class="gen-card" href="/feature-support/m2/">
    <span class="gen-card__name">M2 series</span>
    <span class="gen-card__socs"><span class="soc-id">t8112</span><span class="soc-id">t6020</span><span class="soc-id">t6021</span><span class="soc-id">t6022</span></span>
    <span class="gen-card__count">12 machines</span>
  </a>
  <a class="gen-card" href="/feature-support/m3/">
    <span class="gen-card__name">M3 series</span>
    <span class="gen-card__socs"><span class="soc-id">t8122</span><span class="soc-id">t6030</span><span class="soc-id">t6031</span><span class="soc-id">t6034</span><span class="soc-id">t6032</span></span>
    <span class="gen-card__count">12 machines</span>
  </a>
  <a class="gen-card" href="/feature-support/m4/">
    <span class="gen-card__name">M4 series</span>
    <span class="gen-card__socs"><span class="soc-id">t8132</span><span class="soc-id">t6040</span><span class="soc-id">t6041</span></span>
    <span class="gen-card__count">12 machines catalogued</span>
  </a>
  <a class="gen-card" href="/feature-support/m5/">
    <span class="gen-card__name">M5 series</span>
    <span class="gen-card__socs"><span class="soc-id">t8142</span><span class="soc-id">t6050</span></span>
    <span class="gen-card__count">10 machines catalogued</span>
  </a>
  <a class="gen-card" href="/feature-support/m6/">
    <span class="gen-card__name">M6 series</span>
    <span class="gen-card__socs"><span class="soc-id">t8152</span></span>
    <span class="gen-card__count">1 machine catalogued</span>
  </a>
  <a class="gen-card" href="/feature-support/a18-pro/">
    <span class="gen-card__name">A18 Pro</span>
    <span class="gen-card__socs"><span class="soc-id">t8140</span></span>
    <span class="gen-card__count">1 machine catalogued</span>
  </a>
</div>

## Reading a support state

A result applies to an **operating system, board, feature and tested build**. Shared silicon, a successful compilation, or a merged change does not establish that the same feature works on another machine.

### Windows results

The generation catalogs and device dialogs preserve the project's recorded Windows bring-up results. They use **Working**, **Partial**, **Not working**, and **Not recorded**. An unrecorded feature is not a demonstrated failure. Existing results for `j316s` and `j414s` remain specific to those boards.

### Aurora Linux evidence

The Linux pages distinguish what exists in source from what a named board has demonstrated:

| Evidence | Meaning |
| --- | --- |
| Reported on hardware | A linked report identifies the board, feature and tested revisions; its limits still apply. |
| Published / integrated source | Public code or board integration exists. This alone does not prove operation on hardware. |
| Development / partial | A feature branch, open PR, incomplete integration or qualification remains. |
| Not audited / unverified | The available assessment does not establish the result. This does not mean unsupported. |
| Known / source gap | The cited report or pinned source identifies a missing or failing capability. |
| Not fitted | The hardware is absent from this product. |

The [Linux directory](linux/overview.md) records the **1 October 2026** snapshot, source revision and per-product evidence. M1–M3 have source assessments; J700 has its own public assessment; M4–M6 are not yet audited. These Linux findings do not change the Windows states.

## Where the identifiers come from

The original catalog draws on Apple device trees in Linux and the Asahi Linux [SoC codename table](https://asahilinux.org/docs/hw/soc/soc-codenames/). The expanded catalog follows the [public Aurora hardware directory](https://github.com/aurora-silicon/linux/discussions/70), including its board-specific links to The Apple Wiki and pinned Aurora device trees.

A public identity record is not a support guarantee or evidence that an upstream device tree exists. The M5 Pro / Max / Ultra mapping to `t6050` is retained as a source-qualified catalog entry, not a claim of identical hardware. Each product's Linux page keeps its identity references and assessment boundaries.

To contribute a result, use the [hardware-report template](../developers/testing.md#hardware-report-template) and the product's canonical discussion.
