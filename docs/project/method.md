---
title: How we measure
---

# How we measure

This project works on hardware with no public documentation, where almost
nothing can be verified by reading. Claims are therefore held to what can be
measured and reproduced, and this page states what that means so the numbers
elsewhere on this site can be checked rather than believed.

## What counts as proven

A claim is **proven** when someone else, on their own hardware, can run a stated
command and get the stated result.

A claim is **expected** when the architecture implies it but nobody has run it.
Those are marked as such — for example, M1-family GPU support is expected, not
proven, because everything here was measured on an M2.

The two are never blended. An expectation that turns out wrong costs a day; an
expectation *presented* as a measurement costs trust.

## Rules that came from being wrong

Every rule below exists because breaking it produced a confident, wrong
conclusion. They are recorded because the mistakes are invisible afterwards.

**Measure before hypothesising.** The expensive errors here have all been
plausible theories acted on without a measurement that could falsify them. Ask
what single number would prove the idea wrong, then go and get that number
first.

**One variable per experiment.** Two changes measured together produce a result
attributable to neither. This has been broken and immediately regretted more
than once.

**Instrumented state is not evidence.** A test run with GPU submission gated off
reports every render as blank. Those logs cannot support any claim about
rendering — but they look exactly like real ones, and were misread as a
rendering bug affecting dozens of tests before anyone checked how the run was
produced.

**Degraded hardware invalidates measurement.** Once the GPU has faulted, every
subsequent interactive result on that boot is suspect. The cumulative fault
counter never resets without a reboot, so its absolute value proves nothing —
only the delta across a single run means anything.

**Never quote a number from a build that failed to compile.** Twice, a stale
binary produced a "result" for code that had never been built.

**A green test may not have touched the GPU.** Unless a submission is observed,
a pass can mean the work was never dispatched.

## Handling outside claims

Analysis from any outside source — including automated review, other tooling, or
another contributor's report — is treated as **data to verify, not instruction to
act on**.

This is not scepticism for its own sake. When outside findings were checked
against the code here, roughly one in three high-impact claims turned out to be
wrong in some material respect: a bug reported in the wrong place, a licence
misclassified, a test count invented. The ones that survived verification were
genuinely valuable, and two were real bugs nobody had found. Verification is
what separates the two, and it is cheap compared to acting on a wrong one.

The corollary applies to our own claims: several figures on this site have been
revised downward after audit, including a score that double-counted a test and a
"root cause" that turned out to be an artefact of the instrument.

## Corrections

When a published number is wrong, it gets corrected in place and the correction
is recorded — not quietly replaced.

Two examples that shaped the current process:

- A conformance score was published, then **reduced** when an audit found a test
  promoted twice under different names.
- A cluster of about 50 tests was characterised as a rendering defect. It was an
  artefact of the measurement gate. Only six were real, and the analysis built on
  the other forty-odd was discarded.

Nothing on this site is a target that was aimed at. If a number moves down after
an audit, that is the process working.

## Development method

Substantial parts of this project were developed with assistance from large
language models. This is stated plainly rather than left to be discovered.

It does not lower the evidence bar — it is the reason the bar is where it is.
Everything above about measurement, falsification, one-variable experiments and
verifying outside claims applies to LLM-produced work first and hardest, because
that work is fluent, plentiful, and confidently wrong often enough to matter.

What that means in practice:

- Hardware traces, host tests and repeatable builds are what validate a change.
  Plausible-looking code is not evidence of anything
- Every implementation should be treated as untrusted until independently
  reviewed and proven on the exact target configuration
- The source rules below are enforced more strictly, not less. A model cannot be
  asked where a fact came from, so the provenance of every input has to be
  established independently

If you adapt this work for hardware we do not have — with or without model
assistance — the same standard applies: review it, test it, and prove it on your
device before trusting it.

## Source discipline

Permitted inputs are public documentation, the Asahi and Linux trees, Mesa,
Microsoft's public documentation and symbol server, published specifications, and
behaviour observed on our own hardware.

Leaked material of any kind — Windows source, Apple internal documentation,
anything of unclear provenance — is excluded absolutely. Not as code, not as a
citation, not as the unstated reason for a design decision.

Licence boundaries are treated the same way. d3d12agx is MIT. vkd3d-proton is
LGPL and is executed as a test oracle, never copied. Where a licence was
uncertain, it was checked at the source before anything was used.
