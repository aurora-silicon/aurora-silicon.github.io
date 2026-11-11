# Editing this site

Rules for anyone, person or agent, changing aurora-silicon.github.io. Ryan set them; change them only when he asks.

## Status on the device page

The data is `src/data/support.json`. Device support lives there and nowhere else: other pages link to `/devices/`, never repeat it.

A hardware status may only be raised once the code is merged in `integration/aurora`, our kernel release branch, or for userspace, merged in the shipping package repos (fedora-aurora, alarm-aurora, nixos-aurora). Code on other branches, lab test kernels and open pull requests does not count, whatever it did on a test machine.

There are exactly four states, with this wording everywhere:

- Working: the whole feature works, with the code merged as above.
- Partial: part of the feature works in merged code. Say which part.
- Not working: nothing usable is merged.
- Not recorded: not tested, or no evidence. Never guess a state; leave the entry out.

Windows: every row is Not working until a Windows release ships.

A note is one line per part, in the form `State: part.`, for example `Working: low-power mic.` The pill is derived from its lines: all Working is Working, all Not working is Not working, anything mixed is Partial. Sleep is one feature with two lines, `suspend to idle` and `suspend to RAM (deep sleep)`.

Notes are facts only, what the user sees. No pull request numbers, dates, fleet, build or release-pipeline talk, and nothing like "lands in the next update".

## Writing

Simple, clean, concise. No LLM-sounding prose: run the humanizer skill on everything before it ships. Site content does not mention LLMs, AI or agents beyond the existing policy page and the disclosure line on the contributing page.

Upstream policy text names Asahi Linux, NT-for-ASi, Mesa, FEX and any project that does not accept AI-assisted work as projects we do not send work to. The upstream Linux kernel is fine.

## Content limits

- No recordings, camera frames, screenshots or personal information about anyone, unless Ryan explicitly chose to publish that item.
- Nothing derived from Apple binaries, firmware or tuning values.
- Full aurora-silicon links. The existing Asahi credit links in the footer and on the attribution page stay as they are.

## Commits and publishing

- Commit trailers: Ryan's `Signed-off-by` and `Assisted-by: LLM`, nothing else. Never a Claude co-author or session line.
- `AUTHORS` is for people who write the site's content or code: pages, components, layout, docs, tooling. When you contribute that, add the human contributor to `AUTHORS` in the same pull request, one person per line with their GitHub handle. No bots, no AI. Device status reports and test results do not make someone an author; they are credited where the data is shown if the site already does that, otherwise not at all.
- Never merge or deploy without Ryan's OK.
- `npm run build` must pass, with the internal link check clean.
