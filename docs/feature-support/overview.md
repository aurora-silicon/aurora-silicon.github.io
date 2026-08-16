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
    <span class="gen-card__count">6 machines catalogued</span>
  </a>
  <a class="gen-card" href="/feature-support/m5/">
    <span class="gen-card__name">M5 series</span>
    <span class="gen-card__socs"><span class="soc-id">t8142</span><span class="soc-id">t6050</span></span>
    <span class="gen-card__count">1 machine catalogued</span>
  </a>
  <a class="gen-card" href="/feature-support/a18-pro/">
    <span class="gen-card__name">A18 Pro</span>
    <span class="gen-card__socs"><span class="soc-id">t8140</span></span>
    <span class="gen-card__count">1 machine catalogued</span>
  </a>
</div>

## Reading a support state

!!! warning "Support states are not recorded yet"

    The catalog below identifies hardware; it does not yet claim anything about
    what works. Per-machine support states, and the legend that goes with them,
    still need to be defined and filled in.

Two rules apply once states do appear here. A state is recorded against a device
ID, not a marketing name — "M2 Pro works" is not a claim this section can make,
because the M2 Pro appears in four different machines. And a result on one
machine never transfers to a sibling, however similar: the chip may be shared,
but the board, display, and peripherals are not.

## Where the identifiers come from

Device and SoC IDs on this page are taken from the Apple device trees in the
Linux kernel and from the Asahi Linux
[SoC codename table](https://asahilinux.org/docs/hw/soc/soc-codenames/), which
is the reference for chips that do not yet have upstream device trees.
