---
title: Platforms
---

# Platforms

Aurora Silicon's work spans Windows and Linux on Apple Silicon Macs, alongside
boot firmware, tools and hardware research used to develop those systems.
Choose the operating system you want to run, then check your exact device ID.

<div class="platform-grid">
  <a class="platform-card" href="windows/" aria-label="Windows guide">
    <span class="platform-card__eyebrow">Windows on ARM</span>
    <span class="platform-card__title">Windows</span>
    <span class="platform-card__description">Boot integration, HAL extensions and device drivers.</span>
    <span class="platform-card__footer">Explore Windows <span aria-hidden="true">→</span></span>
  </a>
  <a class="platform-card" href="linux/" aria-label="Linux guide">
    <span class="platform-card__eyebrow">Kernel &amp; device bring-up</span>
    <span class="platform-card__title">Linux</span>
    <span class="platform-card__description">Kernel development, boot tooling and graphics research.</span>
    <span class="platform-card__footer">Explore Linux <span aria-hidden="true">→</span></span>
  </a>
</div>

## What a platform listing means

These are areas of development, not promises of an installable release or equal
hardware coverage. The [support catalog](../feature-support/overview.md) records
results separately for each **device ID and operating system**. A Windows result
does not establish Linux support, and a Linux result does not establish Windows
support. An empty record means **Not recorded**, not working or broken.

The catalog currently carries Windows records for `j316s` and `j414s`. Linux
per-machine records have not yet been published here. That describes this site's
coverage, not the full extent of Linux development or upstream support.

## Shared work and development hosts

Hardware research and boot tooling can inform both platforms, but each target
OS still needs validation. macOS also appears in setup, recovery and research
workflows; it is not a third Aurora operating-system port. A development host's
OS is a separate requirement from the OS being tested on the Mac.

See [Developers](../developers/getting-started.md) for choosing a component and
[Research](../research/overview.md) for the underlying hardware work. Other
operating systems have no support records on this site.
