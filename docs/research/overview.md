---
title: Research Overview
---

# Research

Notes on how Apple's hardware actually behaves, and what a Windows
implementation has to do about it. These pages record findings rather than
instructions — the working detail lives in the repositories.

## Areas

<div class="attrib-grid" markdown>

<article class="attrib-card" markdown>

### HAL Extension

The Apple Interrupt Controller across its generations, and the Windows HAL
extension work around it.

<p class="topic-links" markdown>
[AIC1](hal-extension/aic1.md)
[AIC2](hal-extension/aic2.md)
[AIC3](hal-extension/aic3.md)
</p>

</article>

<article class="attrib-card" markdown>

### GPU

Graphics work on Apple's AGX, including a Direct3D 12 driver written directly
against the hardware.

<p class="topic-links" markdown>
[d3d12agx](gpu/d3d12agx.md)
</p>

</article>

<article class="attrib-card" markdown>

### Networking

The wireless hardware, which changes vendor at the M5 generation.

<p class="topic-links" markdown>
[Broadcom](networking/broadcom.md)
[Apple](networking/apple.md)
</p>

</article>

<article class="attrib-card" markdown>

### Security

Apple's boot policy and secure hardware, and what Windows expects of them.

<p class="topic-links" markdown>
[Touch ID](security/touch-id.md)
[Secure Boot](security/secure-boot.md)
</p>

</article>

</div>

Most of these are not written up yet; each page says so where that is the case.

Research findings stay within Aurora Silicon spaces and are not sent upstream —
see [Policies & Guidelines](../project/policies-and-guidelines.md).
