---
title: Introducing Linux on MacBook Neo
description: An alpha release of Linux on MacBook Neo, built by the Aurora Silicon and Omarchy Mac teams.
date: 2026-10-19
---

We're proud to finally present to you an alpha release of Linux support for MacBook Neo. It is possible due to the extensive efforts of the Aurora Silicon and Omarchy Mac teams working together. While labeled as an alpha, it is (_hopefully_) a super-polished experience offering full access to the range of Neo's hardware and subsystems. This includes, but is not limited to:

- Full-featured display controller with support for an external display up to 4K @ 60 Hz.
- GPU drivers featuring Vulkan 1.4 and OpenGL 4.6 (passing CTS - not certified) with amazing performance & efficiency in games, on top of daily use productivity apps.
- Full media stack: Speakers (protected by speakerguardd, our own safety daemon), Mics (high-quality array and low-power for developers), Webcam (ISP), and 3.5mm audio jack (including support for Apple's EarPods remote).
- WiFi and Bluetooth via a fullmac MediaTek driver (MediaTek being a Neo only/first for Apple Silicon Macs).
- Touch ID (on models that have it), and yes, it works alongside macOS.
- Support for both USB3 and USB2 ports, with graceful hotplug support and platform quirk handling.
- Hardware Video Decoding (via AVD).
- Of course, the keyboard and trackpad (somehow, Apple managed to change up the trackpad a little).

And it goes without saying, much thanks to the incredible work of the Asahi team & its contributors, for all the work they've done. This project does rest strongly on the shoulders of giants. We provide clear attribution throughout all our work, and respect where it is due.

Omarchy is the flagship experience on Neo, and we can't thank David and the Omarchy team[^omacom] enough for the support they've given us, in both tokens and hardware.

Our team has done incredible work, from zero to 100% (and possibly beyond) in the bring-up of new and undocumented hardware. We're all very stoked to share this experience with you all.

This is only the beginning. Our vision is big and clear, all Macs must run the operating system of your choice, and with full support for the hardware it has, exceeding wherever possible the native experience. We're also doing work on making gaming on Apple Silicon hardware better. Keep reading, you're in for a whole lot of fun!

## Once upon a time...

Funny enough, before we began work on Neo, we were porting NT (more colloquially known as the Windows kernel) to Apple Silicon under the project Aurora Silicon. This is a story (with provenance and attribution) to share for another day. We knew we'd eventually tackle new Macs, but it came sooner than later. Ryan[^ryan] got his hands on a new MacBook Neo thanks to a Marketplace deal, and started poking around using m1n1, on top of Yureka's incredible foundational work[^yuka]. Yureka wrote the initial T8140 support that landed upstream in [m1n1 #572](https://github.com/AsahiLinux/m1n1/pull/572), and a build from that tree was our Stage 1 for most of the bring-up. It was very early at that point - we had single core working, no WFI, no USB (just DebugUSB/KIS for proxy - USB on Neo was a _pain_).

But anything is possible!

![Neo first m1n1](/blog/macbook-neo/neo_first_m1n1.webp)

We expect(ed) it would be smooth sailing from there. Since agents can just iterate over proxy and, realistically, get anything working, including loading the kernel over USB. That's pretty much how it goes for most subsystems as soon as you have a little idea of what you're doing or a strong will to "just figure it out" (we all came with no prior knowledge about the platform initially). m1n1 proxy + `macvdmtool` go _brrr_!

## But, it's Apple!

There were however some quirks with SMP (err, AMP, as Ryan corrected, but we can just use it ~interchangeably) handling, and especially WFI since the secondary cores lose their state after wake. Yureka has since written up the [same quirk on M4](https://yuka.dev/blog-2026-10-02-linux-m4.html).

And of course, there's certain things changed up entirely in new Macs, we believe since M4 or since macOS 26 firmware in general (we could find out, but it doesn't really matter). Co-processors seemingly cannot be reset. It only happens during deep suspend, and a full fabric reset happens on wake while DCS stays active. So things like quiescing a controller and letting the next stage start it again will not work in our boot chain anymore. Which, as you can imagine, was the status quo beforehand.

First we ran into these problems in ANS, the NVMe controller. m1n1 has to read from the ESP to load stage 2, and U-Boot in turn has to load its EFI payload from the SSD as well. But now, all of them must adopt the live controller. While a little tricky, it worked. You just need to make sure the controller is in a clean state, essentially "reset".

After a couple of iterations (and days), Ryan got SMP and NVMe stable both in Linux.

![Linux Neo](/blog/macbook-neo/image.png)

From there on, to get anything working further at all (at a hardware parity level), we needed to trace macOS and it was clearly not going to be easy (thanks Apple!). SPTM has been enforced on newer Macs since macOS 15, and that makes running macOS as a m1n1 hypervisor guest _really_ difficult. Eventually, what we ended up doing is building our own SPTM emulator utilising Cody Ho's work as a reference point[^cody]. It was an awful amount of work. But, alas, Ryan got it working eventually and macOS ran under HV and reached userspace! It was enough to trace all the things we cared about. With a little extra work, Dj[^dj] was able to boot into the GUI and trace the GPU after fixing up a few things (after all, all IOMMU goes through it).

Liam[^liam] handled SMC and trackpad quirks - which for some reason differed in format. Eryk[^eryk] helped on both and did the early SMC thermal guard for cpufreq, which Ryan then took the rest of the way. Liam also did a lot of the early audio work (more on that below). Miguel (Ace)[^ace] brought the MediaTek radios up in our public tree, with the PCIe bootstrap they sit behind and Bluetooth on top. He also took Dj's video decoder work and qualified it on real hardware, with 1,740 frames matching software decoding byte for byte.

Wi-Fi was a proper team effort. Ryan wrote the driver, and Eryk, who already had his own MT7932 driver going before he joined us, brought that experience to the many hours he spent cleaning it up and validating it for the public tree. He also got the Omarchy Mac installer working on Neo. Satya (satchlj)[^satchlj] fixed G17P GL bugs and made m1n1 read from the SSD faster, and Jaidip has been busy with USB-C displays on the M2 MacBook Air. We've had help from the community as well, with Bartosz (niteria)[^niteria] fixing s2idle timekeeping on Neo (and getting NixOS running on it), and iconidentify's AVD fixes[^iconidentify] feeding into the video decoder we ship.

Onto Dj for the GPU fun, since going from zero to Vulkan is not an easy path!

Dj here! In parallel to Ryan's effort, as soon as I got a Neo, I got compute working through GPU and wired it up to Vulkan pretty quickly.

Rendering was a PITA. Apple changed how the rendering scheduler works in A18 Pro GPU - which is actually just M4 Pro / Max-like as we found out later. Compute was very similar to M3/M4 and M1/M2 in turn. After a lot of bruteforcing and trying to trace macOS, I finally rendered first triangle using Vulkan on Neo:

![Neo Triangle](/blog/macbook-neo/image-1.png)

It's not pretty because the choice of colors was... Codex.

Initially, the approach I took with GPU was to just make enough things work to render GNOME, which should be simple, right?

Eventually, we did.

![GNOME + Firefox](/blog/macbook-neo/image-3.png)

Yeah it's just an offscreen render while DCP was still being broght up. There were a few bugs initially as expected, but it all smoothed out eventually.

## GPU was pain but fun

At this point I knew the kernel driver is looking significantly different. Getting basic stuff to render is one thing, but now we have a whole new architecture to implement for render work submission and whole concurrency/asynchronous submission needs to be modeled around it. And yes, the new scheduler changed some power semantics. To make it more weird, compute work is still the classic queue style from M1/M2 era, but now we need to support both asynchronously! Well, it gets simpler with M5 and M6 GPUs since they are entirely on new architecture for both compute and rendering work (the "SKSM queues" as Apple calls it).

The userspace/ISA looks very similar. M1/M2 were AGX2, and M3-M6 are all AGX3 but a slight variation of it. M3, M4, and A18 Pro are all AGX3b, M5 is AGX3c and M6 is AGX3d.

AGX3 ISA is very different. The instruction packing has changed significantly. I had to make a whole new compiler backend in `mesa`. Command streams look very different as well, launch programs are different... the userspace GPU drivers, simply put, were a huge undertaking. I do not wish this upon humans to hand-write this, but if you really must, go ahead. My best wishes will be with you. And yes that means optimizations also look very different.

For the kernel driver, it took a long, long time to get this right. Agents would need continuous hand holding and be told where to profile what, but eventually, by asking what I would call the "right questions", you can genuinely make rocks think and write a full fledged GPU driver. Usually once they see where the cost is coming from, it's easy to optimize.

Honestly, it was more of an engineering problem than reverse engineering because we know how to drive the GPU, but how do we make the driver squeeze out maximum juice? Except some bits of course where you have to say the magic values for certain power/state control commands and in the right sequence or you will be scratching your head why the GPU is performing bad. This is where AGX tracing under m1n1 hv came in handy. Boot BaseSystem with basic SSH and trace Metal workloads in isolation.

I mean, if you have worked on similar systems at a low-level before and tried to squeeze out every bit of performance, you already think like a computer. Agents, trust me, are really good at this - but in bigger projects with lots of surface area they seem to get distracted easily and focus on the wrong thing.

I cannot emphasize this enough, to get value out of agents, your workflows/harness matters the MOST! If you or the agent can define problems into smaller sets of get X working with set of {constraints} - it will _eventually_ get there. Now obviously you don't want that eventually to be 2 months and burning billion tokens every day! You have to monitor it. If you have too many tokens you can make an agent monitor it too. But in my experience, they're too easily convinced of anything. So I manually monitored and hand held a lot throughout the GPU driver development. I would describe most of it as decision making and catching where the agent goes off the road. It's done stuff like letting GPU power on/off between each submission, so I bet it can't be trusted to `/goal Make Neo GPU drivers, make no mistake`.

While I bet on doing Vulkan 1.4 first since GL support comes easy with Zink (with its own set of bugs that we had to patch...), Miguel did a lot of the base OpenGL work, getting us to 3.3.

After roughly 6 weeks, what we had is a GPU driver that supports Vulkan 1.4 and it performs on par with macOS in terms of raw performance. Optimizing the compiler is still a long shot problem which cannot be solved at once, you need to throw many resources at it. After finishing Vulkan 1.4 CTS suite at 100% pass rate, Gallium came easy. In a matter of few hours, OpenGL 4.6 was fully supported, however some further testing revealed how its CTS is not enough (I mean, compared to the scale of 3.2 million tests in Vulkan 1.4 suite!) and you can run into trivial bugs in browsers, which I did fix all of what I could find.

## Security, security

That's what Apple is known for, and we have to say, they do an incredible job at this. But they make OUR job harder :D

We have SPTM - secure page table monitor resident at GL2. It's essentially isolating IOMMU access and adding an additional layer of security (after all, it's all layers...) such that an XNU kernel escalation is not enough to take over everything. And then you have the Secure Kernel (which Apple calls cL4) at GL1 and its exclave services (basically, userspace of the Secure Kernel) that are like applets that facilitate different parts such as the secure indicator light - the one that Neo does not have hardware indicator for, so it must be drawn and in a secure way, i.e. isolated from XNU even.

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

One of my favourite moments of the whole bring-up was staring at a black screen on the Neo under m1n1 and watching the little camera dot pop up in the top right corner. The exclave drawing it itself, straight into a secure layer of the display pipe. On Linux there's no exclave to draw it by design (this _may_ change under Mach-O boot mode, more to follow). Staring at black screens and a KIS DebugUSB serial log is good fun, as most of the Linux on Apple Silicon community will likely agree.

Speakers needed their own bit of care. On the MacBooks Asahi supports, the amps report back the voltage and current going into each speaker, and speakersafetyd uses those V/I sense lines to keep an eye on how hot the voice coils are getting. Neo's amps (a fixed-gain MAX98360A per channel) don't have those lines at all. macOS gets away with it by running a model on the CPU instead, working out how hot the coils should be from what it's sending them.

So we wrote [speakerguardd](https://github.com/aurora-silicon/speakerguardd), our own speaker protection daemon that does the same on Linux. It reads back the exact audio the amps are being fed and runs it through a thermal model of the coil and magnet, turning the volume down before anything gets too hot. The constants come from the Neo's own speaker tuning, read through Apple's public AudioUnit API. It speaks the same interlock as speakersafetyd, so until it's running the kernel keeps the speakers locked 20 dB below full scale, and if it ever stops they lock again within 250 ms. We plan to make it the default on every Mac we support. And for the record, my test song through all of this was La La Land by Bryce Vine (ft. YG).

<video src="/blog/macbook-neo/neo_speaker_demo.mp4" controls playsinline preload="metadata" width="480"></video>

Back over to Dj for the fun stuff!

## Gaming, duh

OK, Neo has amazing Vulkan drivers (you're welcome), but can it run games!?

Yes, it can. In fact, we went far and beyond to make it happen. Neo's GPU is quite underpowered. It's barely on par with M1 even raw performance wise. But we still squeezed out performance as much as we could in this time frame and it works pretty darn well - smoother than macOS! Which I would honestly call a sloppy experience on Neo. It feels significantly worse than my other Macs. Probably macOS does not like being thermally throttled as much while Linux manages fine.

Native games using Vulkan/OpenGL run amazing.

![Minecraft on Neo](/blog/macbook-neo/image-4.png)

When it comes to Windows games, they'd usually run under Wine and FEX, and well, muvm for 4 KiB page size. That's a recipe for disaster on a device like Neo! Using a VM, its 8 GB of RAM will be crippled. And exactly as expected, Portal 2 ran like crap on it.

I looked further into it. Rosetta on macOS supports 4 KiB page size for apps. Hmm. Hardware clearly supports it. Kernel must be 16 KiB page size because of hardware interfaces like GPU, but user space has no such restrictions, and clearly, Rosetta does just fine?

However, Linux kernel supports one static page size that you specify at build time. But you have to be ambitious! So we set out on an adventure to add support for what I coined "mixed userspace ABI". 16 KiB kernel should be able to run both 16 KiB and 4 KiB userspace processes, if the hardware permits. But this breaks a lot of assumptions in the kernel, and AI was exactly the kind of tool to relentlessly work on this feature, test it thoroughly, and review it. Not only that, we also made sure it supports AArch32 and 64 KiB kernels to allow 64, 16, 4 KiB userspace support. It's a well executed series of patches for Linux kernel in general that we plan to upstream, for now, it is added as an experimental option in the kernel (`CONFIG_ARM64_USER4K_EXPERIMENTAL`) and you pick 4 KiB per process with our `userpages` launcher.

After like 2 days, I was able to run Steam under just FEX and Wine and run a couple of games through it like Portal 2, Fallout: New Vegas, Subnautica and Geometry Dash. Ryan validated quite a few other games such as The Binding of Issac: Afterbirth, Five Nights at Freddy's 1, Firewatch, Goat Simulator, The Stanley Parable Ultra Deluxe and Undertail. He also spent time packaging and validating native steam under arm64 utilising patches where needed for FEX and Proton.

They all ran quite well out of the box given the nature of a mobile processor!

![Portal 2](/blog/macbook-neo/image-5.png)

And yes, this is shipping in all devices we will support, not just Neo. This has serious unlocks for gaming on Linux. It eliminates the need for `muvm` on Apple Silicon!

Note: It came to my attention _after_ I had developed this feature that Google engineers over at Android had come out with [something similar](https://lpc.events/event/20/contributions/2630/) for per-process page size, coincidentally literally 1-2 days later! But I'm confident what we have here is solid and upstreamable, so eventually an RFC will be posted after more review and testing.

Neo is of course not a gaming device by any means. It doesn't have that many resources, so AAA games won't run that well without lowering resolution to mobile scales and expect lower FPS as you would on an iPhone. Light games it handles incredibly well, and even with external display connected. I played Minecraft at 2K @ 120 Hz output and got a solid 120-150 FPS average gameplay! Just make sure to switch to the native Vulkan renderer :)

## Newer GPU features

Yes, we added hardware ray tracing extensions as well as native mesh shading!

![Ray Tracing on Neo](/blog/macbook-neo/image-6.png)

It was a pain. It's a really complicated feature but it passes most if not all CTS finally.

<!-- REVIEW (Dj): mesa #12 numbers back "most" (ray_query 41/48, RT pipeline 2,504/2,507, mesh 6/9, tess-eval ray queries known-broken). Keep "if not all" only if the later RT PRs closed those gaps. -->

## x86 emulation is rough

FEX does an incredible job. On M1/M2/M3 we're able to enable TSO (Total Store Ordering) which lets FEX do more efficient x86 emulation since memory semantics of x86 are pretty much built into the CPU and just need to be enabled (Rosetta uses it). But since M4, Apple has locked that sysreg. Consequently, it is not available on M4 and later anymore, including A18 Pro.

But worry not! We're developing [Aura](https://github.com/aurora-silicon/aura), a new boot loader that can run in normal boot mode, mediate SPTM communications as well as the Secure Kernel, and stay resident as an EL2 monitor. KVM support for Linux guest is still togglable through nested virtualization, so we don't lose any features, except, we gain!

Aura actually started on my M5 Pro, where raw boot mode is broken won't let the secondary CPUs run any code at all. A normal boot object can start them just fine, but then you're stuck running under SPTM, so Aura sits in between.

TSO is one of the interesting sysregs it will unlock, and in turn enable much better x86 emulation performance on Neo. On top of that, it will also unlock sysregs needed for deep suspend support which we are working on cracking.

All in all, we believe TSO support and native 4 KiB userspace processes without `muvm` will be huge for gaming on Linux on Apple Silicon. We're also going to keep optimizing our drivers to ensure a smooth experience all across the board.

There's a lot we've glossed over here. Touch ID bring-up, Aura and its normal boot mode, and the M5 and M6 bring-up sagas all really deserve write-ups of their own.

## We can fix anything

This is real. In a few days, Neo's Vulkan driver was ported to M5 Pro (thanks to Sol ultrafast!) and it can run some AAA games.

Here is Elder Scrolls V: Skyrim Special Edition. Running on M5 Pro, under FEX and Wine, utilizing native 4 KiB pages. It delivers a smooth 45-60 FPS, usually leaning on the upper end.

Minecraft runs at a solid 750-800 FPS (for now, can be more!)

Give us a little more time. We will not disappoint. We are embracing AI like the large majority of industry is, and not looking behind.

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
