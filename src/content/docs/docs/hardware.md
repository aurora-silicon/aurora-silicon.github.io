---
title: Support records
description: How Aurora Silicon records support per machine, feature, and tested software revision.
---

Support is recorded **per machine and per feature**, rather than inferred from a chip generation. A successful result on one Mac does not automatically apply to another Mac with the same chip.

## What a support record needs

| Detail | Why it matters |
| --- | --- |
| Exact Mac model and device ID | Identifies the board and device configuration tested. |
| Operating system and software revision | Makes the result traceable to a particular build. |
| Feature tested | Separates boot, display, input, storage, and networking results. |
| Test method and logs | Helps another contributor reproduce the observation. |
| Limitations | Records partial behavior and known failures. |

## Reading a result

- **Working:** The reported feature worked in the recorded test, within its documented limits.
- **Partial:** Some behavior worked, but there are recorded restrictions or failures.
- **Not working:** The feature was tested and failed in the recorded conditions.
- **Untested:** There is no recorded test. This means unknown.

The device page groups features by the hardware in each Mac. Its current support snapshot uses **Working**, **Partial**, **Untested**, **Not working**, and **Not recorded**. **Untested** means the hardware is described in the kernel but nobody has run it on that Mac yet. Where only an earlier development report is available, it shows **Reported**.

Each Mac also shows whether the Aurora installer has been tested on it. **Installer tested** currently covers the M1 and M2 series (including Pro, Max and Ultra), the M4 Pro MacBook Pro (J614s and J616s) and the MacBook Neo (A18 Pro). On every other Mac, **Installer untested** means nobody has run the installer there yet, even where Linux itself boots.

Open a feature pill for any restrictions and earlier dated reports. Historical results describe their named software revisions and may differ from the current status.

:::note[Device reports]
Use the [device page](/devices/) to find your Mac’s report. Check its software revision and known issues before installing.
:::

## Reporting a test

Follow the relevant repository’s issue template. Include the exact device, revision, steps, expected result, actual result, and logs. Clearly separate observed behavior from assumptions.

Read the [contributor guide](/docs/contributing/) and [project policies](/docs/policies/) before sharing a report.
