---
title: Hello World, Hello Neo ft. Linux
description: An alpha release of Linux on MacBook Neo, built by the Aurora Silicon and Omarchy Mac teams.
date: 2026-10-19
authors: [Dj, Ryan Murray]
---

We're proud to finally present to you an alpha release of Linux support for MacBook Neo. It is possible due to the extensive efforts of the Aurora Silicon and Omarchy Mac teams working together. While labeled as an alpha, it is (_hopefully_) a super-polished experience offering full access to the range of Neo's hardware and subsystems. This includes, but is not limited to:

- Full-featured display controller with support for an external display up to 4K @ 60 Hz.
- GPU drivers featuring Vulkan 1.4 and OpenGL 4.6 (passing CTS - not certified) with amazing performance & efficiency in games, on top of daily use productivity apps.
- Full media stack: Speakers (protected by speakerguardd, our own safety daemon), Mics (high-quality array and low-power for developers), Webcam (ISP), and 3.5mm audio jack (including support for Apple's EarPods remote).
- Wi-Fi and Bluetooth via a fullmac MediaTek driver (MediaTek being a Neo only/first for Apple Silicon Macs).
- Touch ID (on models that have it), and yes, it works alongside macOS.
- Support for both USB3 and USB2 ports, with graceful hotplug support and platform quirk handling.
- Hardware Video Decoding (via AVD).
- Real deep sleep at about 0.1 W, through our new Aura boot loader.
- Of course, the keyboard and trackpad (somehow, Apple managed to change up the trackpad a little).

And it goes without saying, much thanks to the Asahi team & its contributors for all the incredible work they've done. This project does rest strongly on the shoulders of giants. We provide clear attribution throughout all our work, and respect where it is due.

Omarchy is the flagship experience on Neo, and we can't thank David and the Omarchy team[^omacom] enough for the support they've given us, in both tokens and hardware.

Our team has done incredible work, from zero to 100% (and possibly beyond) in the bring-up of new and undocumented hardware. We're all very stoked to share this experience with you all.

This is only the beginning. Our vision is big and clear, all Macs must run the operating system of your choice, and with full support for the hardware it has, exceeding wherever possible the native experience. We're also doing work on making gaming on Apple Silicon hardware better. Keep reading, you're in for a whole lot of fun!

## Once upon a time...

Funny enough, before we began work on Neo, we were porting NT (more colloquially known as the Windows kernel) to Apple Silicon under the project Aurora Silicon. This is a story (with provenance and attribution) to share for another day. We knew we'd eventually tackle new Macs, but it came sooner rather than later. Ryan[^ryan] got his hands on a new MacBook Neo thanks to a Marketplace deal, and started poking around using m1n1, on top of Yureka's incredible foundational work[^yuka]. Yureka wrote the initial T8140 support that landed upstream in [m1n1 #572](https://github.com/AsahiLinux/m1n1/pull/572), and a build from that tree was our Stage 1 for most of the bring-up. It was very early at that point - we had single core working, no WFI, no USB (just DebugUSB/KIS for proxy - USB on Neo was a _pain_).

But anything is possible!

![Neo first m1n1](/blog/macbook-neo/neo_first_m1n1.webp)

We expect(ed) it would be smooth sailing from there. Since agents can just iterate over proxy and, realistically, get anything working, including loading the kernel over USB. That's pretty much how it goes for most subsystems as soon as you have a little idea of what you're doing or a strong will to "just figure it out" (we all came with no prior knowledge about the platform initially). m1n1 proxy + `macvdmtool` go _brrr_!

## But, it's Apple!

There were however some quirks with SMP (err, AMP, as Ryan corrected, but we can just use it ~interchangeably) handling, and especially WFI since the secondary cores lose their state after wake. Yureka has since written up the [same quirk on M4](https://yuka.dev/blog-2026-10-02-linux-m4.html).

After a couple of iterations (and days), Ryan got both SMP and NVMe stable in Linux.

![Linux Neo](/blog/macbook-neo/image.png)

From there on, to get anything working further at all (at a hardware parity level), we needed to trace macOS and it was clearly not going to be easy (thanks Apple!). SPTM has been enforced on newer Macs since macOS 15, and that makes running macOS as an m1n1 hypervisor guest _really_ difficult. Eventually, what we ended up doing is building our own SPTM emulator utilizing Cody Ho's work as a reference point[^cody]. It was an awful amount of work. But, alas, Ryan got it working eventually and macOS ran under HV and reached userspace! It was enough to trace all the things we cared about. With a little extra work, Dj[^dj] was able to boot into the GUI and trace the GPU after fixing up a few things (after all, all IOMMU goes through it).

Liam[^liam] handled SMC and trackpad quirks - which for some reason differed in format. Eryk[^eryk] helped on both and did the early SMC thermal guard for cpufreq, which Ryan then took the rest of the way. Liam also did a lot of the early audio work (more on that below). Miguel (Ace)[^ace] brought the MediaTek radios up in our public tree, with the PCIe bootstrap they sit behind and Bluetooth on top.

Wi-Fi was a proper team effort. Ryan wrote the driver, and Eryk, who already had his own MT7932 driver going before he joined us, brought that experience to the many hours he spent cleaning it up and validating it for the public tree. He also got the Omarchy Mac installer working on Neo. Satya (satchlj)[^satchlj] fixed G17P GL bugs and made m1n1 read from the SSD faster. We've had help from the community as well, with Bartosz (niteria)[^niteria] fixing s2idle timekeeping on Neo (and getting NixOS running on it), and iconidentify's AVD fixes[^iconidentify] feeding into the video decoder we ship.

Onto Dj for the GPU fun, since going from zero to Vulkan is not an easy path!

Dj here! In parallel to Ryan's effort, as soon as I got a Neo, I got compute working through GPU and wired it up to the Vulkan driver pretty quickly.

Rendering was a PITA. Apple changed how the rendering scheduler works in A18 Pro GPU - which is actually just a smaller M4 Pro / Max GPU as we found out later. Compute was very similar to M3 / M4 and M1 / M2 even. After a lot of trial and error and trying to trace macOS, I finally rendered the first triangle using Vulkan on Neo:

![Neo Triangle](/blog/macbook-neo/image-1.png)

It's not pretty because the choice of colors was... Codex.

Initially, the approach I took with GPU was to just make enough things work to render GNOME, which should be simple, right?

Eventually, we did.

![GNOME + Firefox](/blog/macbook-neo/image-3.png)

Yeah it's just an offscreen render while DCP was still being brought up. There were a few bugs initially as expected, but it all smoothed out eventually.

## GPU was pain but fun

At a high level, GPUs run two kinds of jobs: rendering and compute. Both can be submitted asynchronously, and on Apple GPUs they go to different kinds of firmware queues. We never talk to the GPU directly, only through its firmware.

At this point I knew the kernel driver would look significantly different. Getting basic stuff to render is one thing, but now we have a whole new architecture to implement for render work submission and whole concurrency/asynchronous submission needs to be modeled around it. And yes, the new scheduler changed some power semantics. To make it more weird, compute work is still the classic queue style from M1 / M2 era, but now we need to support both asynchronously!

Compute on Neo was the simpler half, because architecture-wise it looked like what the Asahi GPU driver already does. The structures and ABI had still changed, since we're on a newer macOS firmware (26.6.2).

Things get simpler with M5 and M6 GPUs, which are entirely on the new architecture for both compute and rendering work (the "SKSM queues", as Apple calls them).

The firmware itself moved too. Previously there was a single mailbox, but on A18 Pro it is split in two, `gfx` and `gfx1`. The primary takes all of our submissions and control messages. We set up the secondary at boot, and from then on we only read events and traces back from it. Whatever else it does inside the firmware hasn't mattered to us yet.

M1 / M2 were AGX2, and M3-M6 are all AGX3 so far, with a new variant each generation since M5. We can call it a superset, but there are pretty significant changes. M3, M4, and A18 Pro are all AGX3b, M5 is AGX3c and M6 is AGX3d.

AGX3 ISA is very different. The instruction packing has changed significantly. I had to make a whole new compiler backend in Mesa. Command streams look very different as well, launch programs are different... the userspace GPU drivers, simply put, were a huge undertaking. I do not wish this upon humans to hand-write this, but if you really must, go ahead. My best wishes will be with you. And yes, that means optimizations also look very different.

The encoding is much bigger. AGX2 has 136 instruction forms, 2-10 bytes long. AGX3b on the other hand has 333 forms, 2-20 bytes. AGX3c has 404 such forms (!), up to 22 bytes.

For example, `iadd` is 8 bytes on AGX2 with a 6-bit opcode, and 10 bytes on AGX3b with an 11-bit one. On M5 (AGX3c) it splits into `iadd32` / `iadd64` at 12 bytes, with the opcode spread across four separate bit fields.

Furthermore, on AGX2 `wait` was its own instruction, with 2 scoreboard slots. AGX3b puts a 6-bit wait mask inside _every instruction_, and AGX3c has 8 such slots. Instruction scheduling and load latency now work in a completely different way.

The shader cores were significantly reworked too, around what Apple calls Dynamic Caching: on-chip memory for registers is allocated as shaders run, so register usage no longer decides how many threads fit on a core the way it did on M1.

For the kernel driver, it took a long, long time to get this right. Agents would need continuous hand holding and be told where to profile what, but eventually, by asking what I would call the "right questions", you can genuinely make rocks think and write a full-fledged GPU driver. Usually once they see where the cost is coming from, it's easy to optimize.

Honestly, it was more of an engineering problem than reverse engineering because we know how to drive the GPU, but how do we make the driver squeeze out maximum juice? Except some bits of course where you have to say the magic values for certain power/state control commands and in the right sequence or you will be scratching your head why the GPU is performing bad. This is where AGX tracing under m1n1 hv came in handy. To capture the AGX traces with minimal noise, boot BaseSystem with basic SSH and trace Metal workloads in isolation. This way you wouldn't be capturing the whole macOS GUI rendering during startup or while you trace your workloads, so the traces are easier for agents to make sense of.

If you have worked on similar systems at a low-level before and tried to squeeze out every bit of performance, you already think like a computer. Agents, trust me, are really good at this - but in bigger projects with lots of surface area they seem to get distracted easily and focus on the wrong thing.

Your workflow matters the most here. If you or the agent can define problems into smaller sets of get X working with set of `{constraints}` - it will _eventually_ get there. Now obviously you don't want that eventually to be 2 months and burning a billion tokens every day. You have to monitor it. If you have too many tokens you can make an agent monitor it too. But in my experience, they're too easily convinced of anything. So I manually monitored and hand held a lot throughout the GPU driver development. I would describe most of it as decision making and catching where the agent goes off the road. It's done stuff like letting GPU power on/off between each submission, because it misunderstood macOS's power management commands submitted to GPU firmware, so I don't think it can be trusted to `/goal Make Neo GPU drivers, make no mistake`.

While I bet on doing Vulkan 1.4 first since GL support comes easy with Zink (with its own set of bugs that we had to patch...), Miguel did a lot of the base OpenGL work, getting us to 3.3.

After roughly 6 weeks, what we had is a GPU driver that supports Vulkan 1.4 and it performs on par with macOS in terms of raw performance. Optimizing the compiler is still a long-term problem which cannot be solved at once, you need to throw many resources at it. After finishing Vulkan 1.4 CTS suite at 100% pass rate, Gallium came easy. In a matter of a few hours, OpenGL 4.6 was fully supported, however some further testing revealed how its CTS is not enough (I mean, compared to the scale of 3.2 million tests in Vulkan 1.4 suite!) and you can run into trivial bugs in browsers, and I fixed all of the ones I could find.

Relying on Zink early on also turned up a few Zink bugs. For example, the [Three.js WebGL clipping demo](https://threejs.org/examples/webgl_clipping.html) crashed the GPU in Chromium when it ran through Zink, but not when Chromium used its Vulkan backend directly. (Our native Gallium driver had already been fixed separately.)

## Security, security

That's what Apple is known for, and we have to say, they do an incredible job at this. But they make OUR job harder :D

We have SPTM - secure page table monitor resident at GL2. It's essentially isolating IOMMU access and adding an additional layer of security (after all, it's all layers...) such that an XNU kernel escalation is not enough to take over everything. And then you have the Secure Kernel (which Apple calls cL4) at GL1 and its exclave services (basically, userspace of the Secure Kernel) that are like applets that facilitate different parts such as the secure indicator light - the one that Neo does not have a hardware indicator for, so it must be drawn and in a secure way, i.e. isolated from XNU even.

Well, making this run alongside the SPTM emulator was the difficult part, such that Mic/Webcam could work in macOS under HV and we can finally trace how to use this hardware from Linux. Ryan did it all, with Liam probing away relentlessly! Traced exclaves and got Mic, ISP and ALS functioning in Linux without exclaves since it is not required in raw boot mode.

I'll let Ryan take this one, it was his rabbit hole.

Ryan here! Getting macOS to userspace under the HV was only half of it. As soon as you open the camera or play a sound, macOS stops talking to the hardware directly and asks an exclave to do it instead. With an emulated SPTM and no Secure Kernel, nothing answers. No webcam, no mic, no light sensor, not even the speakers. The AOP (the always-on co-processor that owns all of audio) is powered on through a secure mailbox, and without an exclave macOS never sees a single audio device.

Liam was the first to pin this down for audio, finding that the AOP announces its audio endpoints but the exclave is what turns them on. Working from my HV traces and research, he then got the first tones out of the speakers and the 3.5mm jack straight from m1n1, and had the mic recording too. That proved we could drive the hardware without macOS, and the Linux audio drivers grew from there. The high-quality mic array turned out not to be an exclave device at all, just a normal AOP audio device (`hpai`) sitting next to the speakers. The exclave only guards the DMA channel it uses.

So the HV had to host the Secure Kernel too. That meant bringing up cL4 and ExclaveOS inside m1n1's HV next to the SPTM emulator, and keeping it alive while XNU booted. The secure scheduler deadlocked because we dropped a lock at the wrong time, and opening About This Mac crashed the kernel because our emulator only had room for 32 GPU address spaces and the desktop was already using 30. Hundreds of runs later, macOS finally reported AllExclavesBooted under our HV.

Along the way Dj and I decided we weren't going to run Linux on top of any of this. Instead, we'd trace what the Secure Kernel and its exclaves actually do to the hardware and write that as normal Linux drivers. Raw boot has no exclaves at all, so if we could see the writes, we could do them ourselves.

The webcam's secure side ended up being small, just a fixed set of register writes and a watchdog that needs petting 30 times a second. macOS only pets it while the camera indicator is healthy, so on Linux the ISP driver pets it itself. The ambient light sensor needs one 80-byte calibration message through the AOP's secure mailbox before it reports anything. We captured it once from macOS, and Linux sends the same bytes every boot.

This was the first still with no macOS in the picture at all, straight from m1n1. That's my Logitech BRIO in the corner, which spent a lot of the bring-up watching the Neo's screen for me.

![First ISP still on raw m1n1](/blog/macbook-neo/neo_first_isp.jpg)

About a week after we made that call, all of it was working on Linux, with the webcam running at 30 fps.

One of my favorite moments of the whole bring-up was staring at a black screen on the Neo under m1n1 and watching the little camera dot pop up in the top right corner. The exclave drawing it itself, straight into a secure layer of the display pipe. On Linux there's no exclave to draw it by design (this _may_ change under the non-raw boot mode, more to follow). Staring at black screens and a KIS DebugUSB serial log is good fun, as most of the Linux on Apple Silicon community will likely agree.

Speakers needed their own bit of care. On the MacBooks Asahi supports, the amps report back the voltage and current going into each speaker, and speakersafetyd uses those V/I sense lines to keep an eye on how hot the voice coils are getting. Neo's amps (a fixed-gain MAX98360A per channel) don't have those lines at all. macOS gets away with it by running a model on the CPU instead, working out how hot the coils should be from what it's sending them.

So we wrote [speakerguardd](https://github.com/aurora-silicon/speakerguardd), our own speaker protection daemon that does the same on Linux. It reads back the exact audio the amps are being fed and runs it through a thermal model of the coil and magnet, turning the volume down before anything gets too hot. The constants come from the Neo's own speaker tuning, read through Apple's public AudioUnit API. It speaks the same interlock as speakersafetyd, so until it's running the kernel keeps the speakers locked 20 dB below full scale, and if it ever stops they lock again within 250 ms. And for the record, my test song through all of this was La La Land by Bryce Vine (ft. YG).

**Edit:** speakerguardd v2 is a clean-room take on how macOS protects its speakers, covering all three of Apple's protection models. Every safety value comes from the Mac it runs on, read at install from its device tree, factory calibration and tuning, so we can't go past Apple's limits and we don't redistribute any of Apple's work. If the daemon dies, the kernel pulls the speakers within milliseconds.

<video src="/blog/macbook-neo/neo_speaker_demo.mp4" poster="/blog/macbook-neo/neo_speaker_demo_poster.webp" controls playsinline preload="metadata" width="960" height="600"></video>

Back over to Dj for the fun stuff!

## Gaming, duh

OK, Neo has amazing Vulkan drivers (you're welcome), but can it run games!?

Yes, it can. In fact, we went far and beyond to make it happen. Neo's GPU is quite underpowered. It's barely on par with M1 even raw performance wise. But we still squeezed out performance as much as we could in this time frame and it works pretty darn well - smoother than macOS! Which I would honestly call a sloppy experience on Neo. It feels significantly worse than my other Macs. Probably macOS does not like being thermally throttled as much while Linux manages fine.

Native games using Vulkan/OpenGL run amazing.

![Minecraft on Neo](/blog/macbook-neo/image-4.webp)

When it comes to Windows games, they'd usually run under Wine and FEX, and well, muvm for 4 KiB page size. That's a recipe for disaster on a device like Neo! Using a VM, its 8 GB of RAM will be crippled. And exactly as expected, Portal 2 ran like crap on it.

I looked further into it. Rosetta on macOS supports 4 KiB page size for apps. Hmm. Hardware clearly supports it. Kernel must be 16 KiB page size because of hardware interfaces like GPU, but userspace has no such restrictions, and clearly, Rosetta does just fine?

However, the Linux kernel supports one static page size that you specify at build time. But you have to be ambitious! So we set out on an adventure to add support for what I coined "mixed userspace ABI". 16 KiB kernel should be able to run both 16 KiB and 4 KiB userspace processes, if the hardware permits. But this breaks a lot of assumptions in the kernel, and AI was exactly the kind of tool to relentlessly work on this feature, test it thoroughly, and review it. Not only that, we also made sure it supports AArch32 and 64 KiB kernels to allow 64, 16, 4 KiB userspace support. It's a well executed series of patches for Linux kernel memory management in general that we plan to upstream, for now, it is added as an experimental option in the kernel (`CONFIG_ARM64_USER4K_EXPERIMENTAL`) and you pick 4 KiB per process with our `userpages` launcher.

After like 2 days, I was able to run Steam under just FEX and Wine and run a couple of games through it like Portal 2, Fallout: New Vegas, Subnautica and Geometry Dash. Ryan validated quite a few other games such as The Binding of Isaac: Afterbirth, Five Nights at Freddy's 1, Firewatch, Goat Simulator, The Stanley Parable Ultra Deluxe and Undertale. He also spent time packaging and validating native Steam under arm64 utilizing patches where needed for FEX and Proton.

They all ran quite well out of the box given the nature of a mobile processor!

![Portal 2](/blog/macbook-neo/image-5.webp)

And yes, this is shipping in all devices we will support, not just Neo. This has serious unlocks for gaming on Linux. It eliminates the need for `muvm` on Apple Silicon!

Note: It came to my attention _after_ I had developed this feature that Google engineers over at Android had come out with [something similar](https://lpc.events/event/20/contributions/2630/) for per-process page size, coincidentally literally 1-2 days later! But I'm confident what we have here is solid and upstreamable, so eventually an RFC will be posted after more review and testing. Our branch is [up here](https://github.com/aurora-silicon/linux/tree/mm-mixed-userspace-abi).

Neo is of course not a gaming device by any means. It doesn't have that many resources, so AAA games won't run that well without lowering resolution to mobile scales, and expect lower FPS as you would on an iPhone. Light games it handles incredibly well, and even with external display connected. I played Minecraft at 2K @ 120 Hz output and got a solid 120-150 FPS average gameplay! Just make sure to switch to the native Vulkan renderer :)

## Newer GPU features

Yes, we added hardware ray tracing extensions as well as native mesh shading!

![Ray Tracing on Neo](/blog/macbook-neo/image-6.webp)

It was a pain. It's a really complicated feature but it passes most of the CTS finally. Still a WIP feature as we smooth it out further.

## x86 emulation is rough

[FEX does an incredible job](https://fex-emu.com/Scourge-of-emulation/). On M1/M2/M3 we're able to enable TSO (Total Store Ordering) which lets FEX do more efficient x86 emulation since memory semantics of x86 are pretty much built into the CPU and just need to be enabled (Rosetta uses it). But since M4, Apple has locked that sysreg. Consequently, it is not available on M4 and later anymore, including A18 Pro.

But worry not! We're developing [Aura](https://github.com/aurora-silicon/aura), a new boot loader based on m1n1 that can run in normal boot mode. Due to CTXR limitations that iBoot enforces, the kernel needed some adjustments to fit its executable pages only within the iBoot enforced CTXR. KVM support for Linux guest is still available, and since virtual FIQ timer register is unlocked, VMs work fine. And HACR bits can also be reconfigured that allow Windows VMs to work that are otherwise broken. Yep it unlocks ACTLR_EL1 too :D

Aura actually started on my M5 Pro, where raw boot mode wouldn't let the secondary CPUs run any code at all (Apple has since fixed that in the macOS 27.3 beta, more on that below). A normal boot object could start them just fine. This actually solves a lot of problems. Raw boot mode, which Asahi Linux has used all this time, has been constantly broken by Apple since M4. Restricted sysreg access, which not only takes away features but causes bugs such as broken virtual timers / PMU causing issues in VMs, and particularly Windows VMs being entirely broken.

Jeff Queisser[^jq], our hero, came to our Discord having got the secondary CPUs running on his M5 Ultra Mac Studio, and I was really interested in that. Hmm... that must use the normal boot mode then, but that's a lot of effort to bring up DART/SART under that mode especially due to SPTM. But he had figured out something new: normal boot object with a special `kcbz` property set to 0 - this made iBoot jump to our boot object just like a raw object, but with the sysregs unlocked. Not only did this fix SMP on M5 Pro/Max/Ultra before Apple did, it also comes with all the goodies we talked about earlier. This lets us not have to deal with SPTM and just have a raw boot object-like environment.

TSO is one of the sysregs it unlocks, and every Mac on the latest Aura has it now, so x86 emulation is much faster. It also unlocks the sysregs we need for deep sleep, which ships on Neo in this release (more on that below).

## Rosetta has more tricks than TSO

TSO isn't the only thing Rosetta leans on. Apple's cores hide a few more x86 helpers behind implementation-defined (impdef) bits.

- **APFLG** makes ordinary `ADDS`/`SUBS`/`CMP` also compute x86's parity and adjust flags (PF and AF) into two spare bits of the NZCV register
- **AFP** switches the FPU to x86 SSE behavior (NaNs, min/max, and DAZ/FTZ for denormals)
- **PRSV** makes scalar FP ops keep the upper vector lanes, like `addss` does

Without APFLG, an emulator has to work out PF and AF in software after nearly every arithmetic instruction, because `lahf`, `pushf`, `setp` and every `jp` read them.

APFLG has one catch: on every exception the CPU stashes PF/AF in a separate register (ASPSR), and Linux never saves it, so a context switch silently corrupts the flags. We taught the kernel to save and restore all of this per task, KVM guests included, and taught [FEX](https://github.com/aurora-silicon/fex/pull/6) to keep PF/AF in hardware with APFLG.

On an M2 Pro, with the same FEX build and APFLG turned on:

| Workload | Faster by |
| --- | --- |
| `lahf` | 40% |
| Recursive calls | 20% |
| `pushf` | 14% |
| `setnp` (parity) | 12.5% |
| Octane Crypto | 9% |
| gzip -6 | 5.7% |

Hardware TSO does even more. On the same Mac, compared with FEX's software TSO: Python 85% faster, Octane 48-58%, multithreaded 7-Zip 50%, zstd 45-48%, SQLite 41.5%. With both, FEX runs compression workloads at 85-92% of native arm64 speed, and Python, SQLite and Lua at 70-75%.

M3 and later, including Neo's A18 Pro, have Arm's own FEAT_AFP, which covers the floating-point part. On Neo that leaves TSO and APFLG. Like TSO, these are all ACTLR_EL1 bits, so they're locked on Neo under raw boot, and Aura unlocks them.

All in all, we believe TSO and APFLG support and native 4 KiB userspace processes without `muvm` will be huge for gaming on Linux on Apple Silicon. We're also going to keep optimizing our drivers to ensure a smooth experience all across the board.

There's a lot we've glossed over here. Touch ID bring-up, Aura and its normal boot mode, and the M5 and M6 bring-up sagas all really deserve write-ups of their own.

**Update:** Apple actually fixed the SMP issue on M5 Pro / Max / Ultra for raw boot object!

Quote from [macOS 27.3 beta](https://developer.apple.com/documentation/macos-release-notes/macos-27_3-release-notes#mBoot):

> Fixed: Only a single core is available when you boot Linux or other third-party operating systems from a custom raw boot object on Mac computers with M5 Pro, M5 Max, and M5 Ultra chips. (182898702) (FB23916610)

It references the feedback I posted 3 months ago :D So amazing to see Apple recognizing Linux on Apple Silicon. For now raw boot object is still quite limited and has other bugs, but we will try to submit more such reports to bring it on par if everything goes well.

## We can fix anything

This is real. In a few days, Neo's Vulkan driver was ported to M5 Pro (thanks to Sol ultrafast!) and it can run some AAA games.

Here is The Elder Scrolls V: Skyrim Special Edition. Running on M5 Pro, under FEX and Wine, utilizing native 4 KiB pages. It delivers a smooth 45-60 FPS, usually leaning on the upper end.

<video src="/blog/macbook-neo/skyrim_m5pro.mp4" poster="/blog/macbook-neo/skyrim_m5pro_poster.webp" aria-label="Skyrim on M5 Pro" controls playsinline preload="metadata" width="960" height="540"></video>

Minecraft runs at a solid 780-800 FPS (for now, can be more!).

<video src="/blog/macbook-neo/minecraft_m5pro.mp4" poster="/blog/macbook-neo/minecraft_m5pro_poster.webp" aria-label="Minecraft on M5 Pro" controls playsinline preload="metadata" width="960" height="540"></video>

Many other games work already. Counter-Strike 2 runs at 70 FPS (for now) on High settings, and more on Medium and Low on M5 Pro.

<video src="/blog/macbook-neo/cs2_m5pro.mp4" poster="/blog/macbook-neo/cs2_m5pro_poster.webp" aria-label="CS2 on M5 Pro" controls playsinline preload="metadata" width="960" height="540"></video>

Moreover, our Vulkan driver works amazingly on M5 Max and M5 Ultra too, thanks to Erik[^erik] and Jeff[^jq]. I gave the Splash inference engine a new Vulkan backend with optimized SPIR-V kernels, and on our driver it runs Qwen 3.8 27B (6-bit quant) at about 50 tokens/sec on an M5 Pro with 64 GB. Erik adapted that and took it further on M5 Max, which has double the bandwidth and it reaches just short of 100 tokens/sec!

Give us a little more time. We will not disappoint. We are embracing AI like the large majority of the industry is, and not looking behind.

## What's in flight

**Edit:** A lot has moved since we started writing this.

speakerguardd v2 goes live on every Mac at once, as soon as testing and validation is complete. Ryan is also porting macOS's speaker tuning, built on Saku's[^saku] proof-of-concept scripts, so Linux sounds like macOS too and new Macs get protected speakers on day one.

Ryan brought the Neural Engine up on our machines, building on Joshua Warren's[^joshua] driver, and is putting it to work on webcam denoising, background blur and Center Stage style framing, mic noise suppression, and local live captions.

All of the M5 work builds on Dj's[^dj] groundwork on M5 Pro. Thomas Glanzmann (sithglan)[^sithglan] has the MacBook Air M5, Erik[^erik] the M5 Max MacBook Pro, and Jeff[^jq] with Erik the M5 Ultra Mac Studio. Miguel (Ace)[^ace] wrote the first Mac mini M6 GPU backend.

The M4 Pro MacBook Pro runs our kernel daily. Jonathan Goyvaerts[^jonathan] started it, and he and Ryan are taking it much further, for example refining, polishing and adding features such as working HDR and VRR on internal and external panels. He also has D3D12 fixes for vkd3d-proton and compile fixes from games like Astro Bot and Diablo IV. František Balázsy[^fbalazsy] is adding hibernation, AxxzyWasTaken[^axxzy] the M4 Max and Erik the M4 MacBook Air, while Justin Pfister[^jjrpf] and Satya[^satchlj] are working on M2 and M3. M1 and M2 panels now fade brightness smoothly, and the keyboard backlight follows the light sensor like it does on macOS.

On Neo, hardware video encoding is in and the thermal framework now follows macOS's policy. Deep sleep made it in just in time, more on that next. Ryan is working on a big Touch ID rework, starting with multi-user support. Fedora, Arch Linux ARM and NixOS are moving to one unified kernel, Fedora 45 packages are live, and Michal[^michal] is getting NixOS 26.11 ready.

## One more thing...

A long-standing problem in the Apple Silicon Linux ecosystem has been power management. Sleep on Linux has never been real sleep, which makes the standby time ridiculous, and you can never leave it asleep overnight. I cannot wrap my head around how this was acceptable for this many years. It cannot be that hard to poke the right things and make the system _actually_ sleep. This is 100% one of the most essential features of MacBooks. Unless you shut it down, but let's be real, no one is doing that each time.

How do we start? Let's look at what we got here. Asahi supports at least `s2idle`: the cores can sleep using `wfi`, and a lot of hardware is stopped or put to sleep, like the display, Wi-Fi and Bluetooth. On MacBook Neo, that still leaves you at around 1.4 W, and no matter how many more knobs you turn, there is a limit to this. The furthest that got us was turning off DCP's power domain itself, literally shutting the coprocessor down, which brings power usage down to around 0.7 W during sleep.

If you `/goal` and ask an agent to do this, it will try cutting corners like this. But the real deal is deep sleep that macOS does. We _have_ to learn how it does that and just implement it in Linux!

My initial goal was to get macOS running under the hypervisor, we already had that using an SPTM emulator - but I wanted to redo it for the sake of a cleaner approach. In normal boot mode, GXF is unlocked. We can set up GXF and have real GL2 going in Aura. It took about 2 days to get this thing going, and here is the new approach in a nutshell:

- Instead of emulating SPTM, we run the real SPTM binary, virtualized at GL1 (as we run XNU at EL1 under hypervisor)
- Using nested virtualization, we can make XNU think it's running in EL2 normally, and SPTM think it's in GL2 but both are physically in EL1 and GL1 respectively
- We need to have context switching between TXM/XNU/SPTM since all run at the same physical exception level, so some sort of save/restore is needed there otherwise there is state loss/corruption
- Secure Kernel / Exclaves also needed a bit more handling for context switching but mostly worked out of the box

With everything in place cleanly, macOS boots under the Aura hypervisor with Secure Kernel up. Great. Now that I feel happy about the hypervisor, let's see what happens when macOS tries to sleep.

The screen goes off and then it resets in 5 s, back to proxy. WTF!?

I was stuck there for some time until I realized one thing: when committing sleep, macOS essentially does this:

- Tells all coprocessors to shut down / sleep, so they stop cleanly
- Arms a 5 s watchdog in the AON (always-on) domain, which resets the machine if it doesn't reach a proper sleep state
- Commits the sleep which is essentially a few PMU writes, arms wake sources (it's just like a filter, what can wake up the AP) + sets `S3_5_C15_C6_2` bits 0 and 63 to enable deep WFI, then all cores just do WFI
- PMU cuts off the power rail to the SoC after the cluster is down in deep WFI

Essentially, most of the things which can be powered off, go off. What needs to stay awake are explicitly AON domains so we don't touch them. A lot of coprocessors like MTP (which can wake the AP), AOP, etc. are always on, and some USB domains with an `_AON` suffix stay on for purposes like wake from USB.

Now clearly, macOS knows how to program its sleep. The only difference is the hypervisor here. It had something to do with Aura not power gating the boot core, and keeping the debug USB link on, which makes AON panic and think the system is in an inconsistent state. And trapping too much to trace could make the 5 s timeout hit because the sleep commit was too slow.

After fixing those, macOS gets into sleep. But it doesn't wake up, great. Fortunately, it puts together some nice panic reports for us telling us what exactly broke! The very first one was a Secure Kernel state corruption, which turned out to be, again, the hypervisor just not saving the state of the register banks it maintains for each world, XNU / SPTM / TXM, so it caused some state loss. A couple more fixes like that later, and wow, macOS can sleep under the hypervisor! And when it wakes, Aura's debug link comes right back on letting us trace the wake sequence as well.

There's more going on behind the scenes. On wake, a reconfig engine restores SoC state, and iBoot jumps back to its reset vector and enters Aura stage 1 at RVBAR. The rest runs normally from there, so we don't need to handle anything special. The reconfig engine's program is readable from NUB SRAM, where iBoot builds it.

Now being able to trace what macOS does to commit sleep and to wake, we should be able to `/goal` deep sleep in Linux. That was pretty much it but damn these agents are stupid. I'm glad I hand held them and sped up the process otherwise it was going to take way longer. There are many little gotchas. Linux doesn't talk to everything macOS does, and skips many messages it doesn't need. After wiring up all of those fixes in each driver to implement a suspend / wake sequence for all coprocessors, and all the MMIO to properly restore state, everything just works. The system goes to real deep sleep, and it wakes up perfectly.

How did I automate most of this? `sudo pmset relative wake 10 && pmset sleepnow`! This lets you schedule a wakeup in X seconds (X = 10) and make the system sleep, on macOS. Under the hood, it writes to the PMU, so by tracing the PMU, I figured out how to replicate it on Linux as well. There are some other useful pmset options, like disabling Wi-Fi wake, to get clean, interruption-free measurements.

There were some painful things when doing bring-up on the Linux side. At first the ANS (NVMe controller) firmware would not talk, but that was because of missing GPIO state save/restore across suspend. Then it wouldn't train PCIe links due to, again, state not being restored. Debugging the vague silent errors or errors that make no sense in firmware was tricky. Another interesting bit here is that sleeping PMP or `gfx`/`gfx1` is a one-shot thing and they never come back until a full SoC power reset that PMU does on deep suspend. But I think this might be a way to improve GPU iteration times too, if GFX firmware crashes, could we just sleep and wake to fresh GFX? Not sure, maybe.

Neo measures 0.109 W in sleep now, down from 1.4 W, roughly 13× less. Yeah, that's a pretty damn big difference and a huge deciding factor whether you would ever put Linux on your MacBook or not.

Deep sleep ships in this release. It runs on Aura, since raw boot keeps the sysregs it needs locked.

## Support us

Everything we do lives on [GitHub](https://github.com/aurora-silicon). If you'd like to support the work, you can sponsor us directly:

- @djdev - [here](https://github.com/sponsors/djdeveloperr)
- @rttdev - [here](https://github.com/sponsors/RyanTheTide) or [here](https://www.paypal.com/donate/?hosted_button_id=A6XCX8AUBZZDG)

Anyone else on the team can be reached through our [Discord](https://discord.gg/DXmsSSc5aY), whether you'd like to chat or grab a donation link for them. Except Miguel, who "does it for the love of the game".

![Miguel declining a sponsor link](/blog/macbook-neo/miguel_sponsor_nope.png)

More to come!

[^omacom]: [Omacom](https://github.com/omacom), the home of [Omarchy](https://omarchy.org/foundation).
[^ryan]: Ryan Murray, [RyanTheTide](https://github.com/RyanTheTide) on GitHub.
[^yuka]: Yureka on [GitHub](https://github.com/yuyuyureka) and at [yuka.dev](https://yuka.dev).
[^dj]: Dj, [DjDeveloperr](https://github.com/DjDeveloperr) on GitHub.
[^liam]: Liam, [LiamRay11](https://github.com/LiamRay11) on GitHub.
[^eryk]: Eryk Wieliczko, [erykwieliczko](https://github.com/erykwieliczko) on GitHub.
[^ace]: Miguel Cruz, [Acelogic](https://github.com/Acelogic) on GitHub.
[^satchlj]: Satya Benson, [satchlj](https://github.com/satchlj) on GitHub.
[^niteria]: Bartosz Nitka, [niteria](https://github.com/niteria) on GitHub.
[^iconidentify]: [iconidentify](https://github.com/iconidentify) on GitHub.
[^cody]: Cody Ho's M4+ hypervisor work in [m1n1 #622](https://github.com/AsahiLinux/m1n1/pull/622) and his [SPTM and exclaves docs](https://github.com/ADevWithAnIdea/apple-silicon-re). He later wrote up his side in [I Came, I Prompted, I Left Part 1](https://codyho.dev/blog/hypervisor-macbook-neo/).
[^jq]: Jeff Queisser, [funkzy](https://github.com/funkzy) on GitHub.
[^erik]: Erik, [erikwb](https://github.com/erikwb) on GitHub.
[^joshua]: Joshua Warren, [joshuaswarren](https://github.com/joshuaswarren) on GitHub.
[^sithglan]: Thomas Glanzmann, [sithglan](https://github.com/sithglan) on GitHub.
[^fbalazsy]: František Balázsy, [fbalazsy](https://github.com/fbalazsy) on GitHub.
[^axxzy]: [AxxzyWasTaken](https://github.com/AxxzyWasTaken) on GitHub.
[^jjrpf]: Justin Pfister, [JJRPF](https://github.com/JJRPF) on GitHub.
[^jonathan]: Jonathan Goyvaerts, [jgoyvaerts](https://github.com/jgoyvaerts) on GitHub.
[^michal]: Michal S., [mchalunderscore](https://github.com/mchalunderscore) on GitHub.
[^saku]: Saku, whose proof-of-concept scripts are the basis of our speaker tuning extraction.
