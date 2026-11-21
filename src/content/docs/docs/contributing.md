---
title: Getting involved
description: Start contributing to Aurora Silicon through development, testing, research, or documentation.
---

Aurora’s first focus is Linux on Apple Silicon. You can help through development, hardware research, testing, and documentation.

## Before you contribute

Read the [policies and guidelines](/docs/policies/) first, then the README, contribution instructions, and `AGENTS.md` files in the relevant repository. Those instructions define the setup and requirements for that work.

## Pick a starting point

- **Development:** Explore the [repositories](https://github.com/aurora-silicon), understand their scope, and follow their setup instructions.
- **Testing:** Record your exact device, software revision, steps, and logs. Use the [hardware support guide](/docs/hardware/) to make the report reproducible.
- **Research:** Share observations and evidence you have the right to contribute, within Aurora-controlled spaces.
- **Documentation:** Clarify verified instructions, explain limitations, or correct an inaccurate statement with supporting evidence.

## What a mergeable change looks like

These apply to every repository we maintain: the kernel, aura, U-Boot, Mesa, the
installer, speakerguardd and the distributions.

- **It works on the default boot.** A feature must work with the distribution's
  default kernel command line. Do not add kernel command-line options, module
  parameters, environment variables or manual setup steps to make it work. Options
  are fine while you develop; remove them, and test without them, before you open
  the pull request.
- **It selects by hardware, not by model.** Choose behaviour from what the device
  tree and the firmware describe: a property, the block's `compatible` string, a
  capability bit, or a register you probe. Do not add checks on the chip, board,
  Mac model or firmware version. If one is truly unavoidable, explain why in the
  commit message and key it on the narrowest property you can.
- **It is tested on every Mac with that hardware.** A change to a block shared by
  several Macs needs results from each of them, or a clear list of the ones you could
  not test.
- **No delays or magic numbers as fixes.** A sleep, retry count or queue depth that
  the hardware does not describe is not a fix; find the cause.
- **Speakers stay protected.** Speaker work goes through
  [speakerguardd](https://github.com/aurora-silicon/speakerguardd). Never disable
  speaker protection or raise its limits, and do not test speakers without it.

A pull request that does not meet these yet can stay open as a draft.

## Preparing a contribution

Explain the problem, the change or observation, and how you verified it. Make limitations explicit. Follow the repository’s issue or pull request template where one exists.

If generative AI contributed to a submission, disclose that involvement clearly in the associated commit, as required by the project policies. You remain responsible for the submitted content.

Keep project-derived findings, patches, and related technical discussion within Aurora-controlled spaces. Do not send them to upstream projects.
