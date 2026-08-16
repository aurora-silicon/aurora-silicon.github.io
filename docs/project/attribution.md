---
title: Attribution
---

# Attribution

Aurora Silicon is built on a great deal of work done by other people. Booting
Windows on Apple Silicon depends on years of reverse engineering, firmware and
driver work that we did not do, and much of our own tree started as someone
else's.

## Projects

<div class="attrib-grid" markdown>

<article class="attrib-card" markdown>

### Asahi Linux

The reverse engineering effort behind almost everything known publicly about
Apple Silicon. Our bootloader, kernel, U-Boot and installer trees all begin as
forks of theirs; `kisd` and `tuxvdmtool` are host tools we use as they ship;
and their hardware documentation underpins the research notes here.

<p class="attrib-links" markdown>
[:fontawesome-brands-github: GitHub](https://github.com/AsahiLinux)
[:material-web: asahilinux.org](https://asahilinux.org)
</p>

</article>

<article class="attrib-card" markdown>

### NT-for-ASi

Prior work on booting Windows on Apple Silicon: a Project Mu UEFI
implementation for Apple platforms, an m1n1 variant with GIC emulation, and the
Windows HAL extensions and drivers our own HAL research builds on.

<p class="attrib-links" markdown>
[:fontawesome-brands-github: GitHub](https://github.com/NT-for-ASi)
[:material-web: nt-for-asi.github.io](https://nt-for-asi.github.io/)
</p>

</article>

<article class="attrib-card" markdown>

### Project Mu

Microsoft's modular UEFI core. It is the firmware base the Apple Silicon UEFI
implementation is built from, reaching us by way of NT-for-ASi.

<p class="attrib-links" markdown>
[:fontawesome-brands-github: GitHub](https://github.com/microsoft/mu)
[:material-web: microsoft.github.io/mu](https://microsoft.github.io/mu/)
</p>

</article>

<article class="attrib-card" markdown>

### Mesa

The graphics stack our GPU research works within. The `d3d12agx` work covered
under [Research](../research/gpu/d3d12agx.md) is Mesa driver work.

<p class="attrib-links" markdown>
[:material-git: Source](https://gitlab.freedesktop.org/mesa/mesa)
[:material-web: mesa3d.org](https://mesa3d.org)
</p>

</article>

</div>

## People

Individual forks and tools we pull directly into our own tree. Most of this is
MacBook Neo work — it is what the A18 Pro bring-up is built on.

<div class="attrib-grid" markdown>

<article class="attrib-card" markdown>

### Yureka

`yuyuyureka/m1n1`, the most complete Neo lineage we know of: DebugUSB, an m1n1
proxy shell, m1n1-to-Linux chainloading, T8140 PMGR, the dockchannel console,
and later PCIe and NVMe work. Our primary community diff source.

<p class="attrib-links" markdown>
[:fontawesome-brands-github: yuyuyureka/m1n1](https://github.com/yuyuyureka/m1n1)
</p>

</article>

<article class="attrib-card" markdown>

### Robert Rusch

`asahi_neo`, whose captures reported m1n1 reaching EL2 and a framebuffer on a
Neo, and recorded the personalised-kernelcache update method our installer
scripts guard. Also `rusch95/m1n1`, the first reported Neo framebuffer and
proxy boot.

<p class="attrib-links" markdown>
[:fontawesome-brands-github: rusch95/asahi_neo](https://github.com/rusch95/asahi_neo)
[:fontawesome-brands-github: rusch95/m1n1](https://github.com/rusch95/m1n1)
</p>

</article>

<article class="attrib-card" markdown>

### Miyako Yakota

`MiyakoYakota/m1n1`, the Neo Linux payload and SMP source lineage — the report
of a Linux payload booting with six CPUs up.

<p class="attrib-links" markdown>
[:fontawesome-brands-github: MiyakoYakota/m1n1](https://github.com/MiyakoYakota/m1n1)
</p>

</article>

<article class="attrib-card" markdown>

### Dhinak G

`aeota`, the AEA and WKMS reference implementation we rely on to handle modern
IPSW disk images.

<p class="attrib-links" markdown>
[:fontawesome-brands-github: dhinakg/aeota](https://github.com/dhinakg/aeota)
</p>

</article>

<article class="attrib-card" markdown>

### rafalh

`rust-fatfs`, the FAT filesystem crate vendored into m1n1's Rust code and
carried through our fork.

<p class="attrib-links" markdown>
[:fontawesome-brands-github: rafalh/rust-fatfs](https://github.com/rafalh/rust-fatfs)
</p>

</article>

</div>

## This list is not exhaustive

The projects and people above are the ones our work leans on most visibly, but
they are not everyone. Our repositories carry their own attribution, and that is
the authoritative record: each one keeps the upstream licence headers, credits
files and commit history that say precisely where code was taken or reused
from, down to the individual file.

If you believe your work is used here and is not credited properly — in a repo
or on this page — please tell us and we will fix it.
