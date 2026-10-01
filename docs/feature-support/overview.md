---
title: Feature Support
---

# Feature Support

Apple sells one marketing name across several different chips, and puts one chip
in several different machines. Support has to be tracked per machine, so this
section is organised the way the hardware actually is rather than the way it is
advertised.

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

Select a device ID on a generation page to see its Windows features. A feature
with no recorded state is untested, not working by default and not a known
failure.

The Linux bring-up notes sit below the Windows results on each page. They use
three different kinds of evidence: code that exists, a result reported on the
named hardware, and work that is still partial. A driver in the tree is not the
same thing as a working laptop.

| State in the Linux notes | What it means |
| --- | --- |
| Integrated source / published code | The implementation or board description exists in the cited tree. |
| Hardware report | A public test names the board, build and feature that worked. |
| Partial / development | A feature branch, open PR or unfinished part is still involved. |
| Not audited / unverified | A result has not been established for this board. |
| Known gap / source gap | The cited test or source identifies something missing or failing. |
| Not fitted | That machine does not have the hardware. |

A state belongs to one device ID and one operating system. A result on a sibling
machine does not transfer, however similar the chip, and a Linux result does
not establish Windows support. A merged change also needs its destination
branch: `feat/sep` and `aurora-wip` are different trees.

The Linux notes are dated **1 October 2026**, against
[`aurora-wip` at `1d2904fd3301`](https://github.com/aurora-silicon/linux/tree/1d2904fd3301c63620f07c81ae79f2486a81a9a6)
and the development branches named alongside each result. The product threads
linked from each page hold later reports. To add one, use the
[testing guide](../developers/testing.md).

## Where the identifiers come from

Device and SoC IDs come from Apple device trees in Linux, the Asahi Linux
[SoC codename table](https://asahilinux.org/docs/hw/soc/soc-codenames/), and the
[public hardware directory](https://github.com/aurora-silicon/linux/discussions/70).
The latter links the device records used for newer machines, including The
Apple Wiki. An identity record does not establish support or the presence of an
upstream device tree.
