---
title: Contributing
---

# Contributing

Aurora Silicon is a small project working on undocumented hardware. Contributions
are welcome; the bar is that a change has to be *demonstrably* right, because
almost nothing here can be checked by reading alone.

## Where to start

- [Discord](https://discord.gg/DXmsSSc5aY) — the fastest way to find out whether
  something is already being worked on
- [GitHub](https://github.com/aurora-silicon) — issues and pull requests
- [Building](building.md), then [Testing](testing.md)

The most useful contribution right now is **running the conformance suite on
hardware we do not have**. Everything on this site was measured on a single
M2. An M1-family result would turn an architectural expectation into a fact.

## Source rules

These are not negotiable, and they apply to code, documentation and analysis
alike.

**Clean inputs only.** Permitted sources are public documentation, the Asahi and
Linux trees, Mesa, Microsoft's public documentation and symbol server, the
UEFI/ACPI specifications, and behaviour observed on our own hardware.

**Leaked material is excluded absolutely.** Leaked Windows source, leaked Apple
internal documentation, or any material of unclear provenance cannot enter this
project — not in code, not in a comment, not as the reason for a design choice.
A single tainted input can compromise the whole tree permanently.

**Licence boundaries are real.** d3d12agx is MIT, matching Mesa. vkd3d-proton is
LGPL and is used as a test oracle only — executed, never copied. If you are
unsure whether something can be borrowed, ask before writing it, not after.

## Evidence standards

A change that claims to fix something needs a measurement that would have failed
before it and passes after.

- **Quote numbers you actually measured.** Not expected, not inferred from a
  related result
- **One variable at a time.** Two changes measured together produce a result
  attributable to neither
- **Say when something did not work.** A recorded failure saves the next person
  from repeating it. Several of the rules in [Testing](testing.md) exist because
  someone here got it wrong first
- **Revert what does not help.** A change that does not move a measurement is
  not neutral; it is unexplained code

## Documentation

If you fix something that was hard to find, write down *why* it was hard, not
just what the fix was. The fix is usually small and visible in the diff; the
reason it was needed is invisible afterwards and is the expensive part to
rediscover.
