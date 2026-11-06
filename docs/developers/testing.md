---
title: Testing
---

# Testing

How work gets checked before it is trusted, and how results on real hardware are
recorded.

!!! warning "Draft"

    Test procedures and commands are still outlines. The result-recording
    guidance below explains what a new support claim needs to include.

## What we test

*To write: the layers of testing that exist — what can be checked on a
development host, and what can only be checked by booting a machine. Set the
expectation early that most meaningful testing here needs hardware.*

## Running the tests

*To write: the test invocations per tree, what they cover, and what a pass
actually proves.*

## Testing on hardware

*To write: the procedure for testing a build on a real machine, including how to
tell the difference between a bad build and a bad flash, and how to get the
machine back afterwards.*

## Recording a result

Record the device ID **and target operating system**. Results in the
[support catalog](../feature-support/overview.md) are stored by OS, then device,
then feature. Never transfer a result to a sibling machine or another OS.

For a new or updated result, include the OS version (and distribution for
Linux), exact source/build revisions, boot and firmware configuration, test
date, tested behaviour and limitations, and a reviewable evidence reference.
The host OS alone is not enough to identify the system under test. Follow the
website repository's README when editing its support data.

Leave an untested feature at **Not recorded**. Use **Not working** for an observed
failure, and **Partial** when the recorded limitations matter. Existing Windows
records predate this format and still need build and evidence references before
they can be treated as reproducible qualification results.

## Evidence

*To write: what has to accompany a claim for it to be believed — logs, the exact
build, the firmware revision, and the machine it ran on. This is the section
that keeps the support tables honest, so it is worth being strict in.*

## Reporting a failure

*To write: where failures go and what to include. Distinguish a failure worth
filing from a machine that simply has not been brought up yet.*
