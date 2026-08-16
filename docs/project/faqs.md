---
title: FAQs
---

# FAQs

!!! warning "Partly drafted"

    The answers about the project, the hardware and contributing are settled.
    The installation and day-to-day questions are still marked as outstanding
    and should not be treated as accurate until written.

## About the project

### When will Aurora Silicon be finished?

*To write: an honest answer, or an honest refusal to give a date. This is the
question people ask most, so it deserves a direct answer rather than being left
to inference.*

### Is it ready to use?

No. Aurora Silicon is experimental — something to follow, test and help with
rather than depend on. For how far along any particular machine is,
[feature support](../feature-support/overview.md) is the honest answer.

### Does *(some feature)* work yet?

Check [feature support](../feature-support/overview.md) rather than asking. Each
machine has its own page listing what has been recorded against it. A feature
with no recorded state means untested, not working — we do not claim anything we
have not measured on that exact machine.

### Is this the same as Asahi Linux?

No. Asahi Linux is a separate project bringing Linux to Apple Silicon; we are a
separate effort aimed at Windows. Much of our tree began as forks of theirs,
and their work — along with NT-for-ASi and others — is credited under
[Attribution](attribution.md).

## Hardware

### Which Macs does it support?

Support is tracked per machine, not per chip, because Apple ships one chip
across several different machines. The catalog and the state of each machine are
under [feature support](../feature-support/overview.md).

### My Mac has the same chip as a supported one — does that work?

Not necessarily, and we will not claim it does. A result on one machine never
transfers to a sibling: the chip may be shared, but the board, display and
peripherals are not. Every machine is recorded separately, against its own
device ID.

### Will it work on Intel Macs?

No. The project targets Apple Silicon only.

### Can I install it on an iPhone or iPad?

No. We target Macs. The A18 Pro appears here because of the MacBook Neo, not
because of phones or tablets.

## Installing and using

### How do I install it?

*To write: the real answer for the current state of the project, linking to
[installation](../users/installation.md).*

### Can I install it from an external macOS installation?

*To write: whether the installer has to run from the internal system, and what
happens if it does not.*

### Can I run it entirely from a USB drive?

*To write: whether an external-only install is possible, and whether it is
supported or merely something that happens to work.*

### Will it dual-boot alongside macOS?

*To write: what the intended arrangement is, how you pick between systems at
boot, and whether macOS survives installation intact.*

### My Mac keeps booting into macOS instead

*To write: how boot selection actually works and how to change the default. This
is a question upstream gets constantly, so it is worth answering well.*

### Do I need to reinstall to get updates?

*To write: how updates reach an installed system, and whether any of them
require starting over.*

### Will it run x86 Windows applications, or games?

*To write: the real emulation and graphics position. Do not promise anything the
GPU work has not actually delivered.*

### How do I remove it, or clean up a failed install?

*To write: a short answer pointing at [removal](../users/removal.md), covering
both a working system and one that failed partway through, and saying whether
the machine is fully restored afterwards.*

## Contributing

### How can I help?

Start with the [developer guide](../developers/getting-started.md), then read
[Contributing](../developers/contributing.md) before sending anything. Testing
on hardware we do not have is genuinely useful — see
[Testing](../developers/testing.md) for what makes a result usable.

### Can I contribute if I work for Apple or Microsoft?

Only under specific conditions: explicit authorisation from your employer, and
an administrator having reviewed proof of it. This applies to contractors and
subcontractors too. If you are unsure, do not contribute — see
[Policies & Guidelines](policies-and-guidelines.md).

### Can I use an LLM to work on this?

Yes, with conditions. You remain solely responsible for whatever you submit,
your agent must follow the `AGENTS.md` instructions in our repositories, and any
AI-generated content must be disclosed in the commit. The full rules are in
[Policies & Guidelines](policies-and-guidelines.md).

### Can I report our findings to Asahi Linux or NT-for-ASi?

No. Do not send bugs, issues, pull requests or findings derived from this
project to upstream repositories or their maintainers. Our approach to LLM usage
and decompilation differs from theirs, which makes our output unusable from
their perspective. This protects their work rather than hoards ours — the
reasoning is in [Policies & Guidelines](policies-and-guidelines.md).

### Does the project use leaked or confidential material?

No. Sharing NDA-protected or otherwise non-public material is prohibited, and
anything contributed on that basis is removed. Public betas and publicly
available developer betas are the exception. See
[Policies & Guidelines](policies-and-guidelines.md).

## Still stuck?

*To write: where to go next — the Discord, and what to include when asking. Two
or three lines is enough.*
