---
title: Testing
---

# Testing

How work gets checked before it is trusted, and how results on real hardware are
recorded.

!!! warning "Draft"

    This page is an outline. The sections below describe what still needs to be
    written, and no technical detail here should be treated as accurate yet.

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

*To write: how a result becomes a recorded support state on
[feature support](../feature-support/overview.md). Cover the rule that matters
most — a result is recorded against a device ID, never a chip or a marketing
name, and never generalised to a sibling machine.*

## Evidence

*To write: what has to accompany a claim for it to be believed — logs, the exact
build, the firmware revision, and the machine it ran on. This is the section
that keeps the support tables honest, so it is worth being strict in.*

## Reporting a failure

*To write: where failures go and what to include. Distinguish a failure worth
filing from a machine that simply has not been brought up yet.*
