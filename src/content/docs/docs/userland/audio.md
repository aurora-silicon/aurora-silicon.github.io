---
title: Audio stack
description: PipeWire profiles, ALSA files, plugins and the speaker safety daemon for the built-in speakers, jack and microphones.
---

Preinstalled on every Aurora system.

## The pieces

| Package | What it does |
| --- | --- |
| `aurora-audio` | PipeWire and WirePlumber DSP profiles for each Mac's speakers and microphones. Aurora's fork of asahi-audio, which it replaces. |
| `alsa-ucm-conf-aurora` | ALSA use-case files that describe each Mac's audio routes. |
| `speakersafetyd` | The current speaker safety daemon on Macs whose amplifiers report voltage and current. |
| `speakersafetyd-aurora-profiles` | Extra speakersafetyd profiles, including the 16-inch M4 Pro MacBook Pro, and a faster restart. |
| `speakerguardd` | The current speaker safety daemon for the MacBook Neo. |
| `bankstown` | Bass enhancement used by the speaker profiles. |
| `lsp-plugins-lv2` | Loudness compensation, patched to report its real latency. |
| `triforce-lv2` | Beamformer that combines the microphone array into one clean input. |

The next generation of speaker protection, [speakerguardd v2](/docs/userland/speakerguardd/), is an opt-in preview that replaces `speakersafetyd` and `speakerguardd` on a Mac once you switch it over.

On NixOS these come from the `aurora` modules. The asahi-audio and UCM overlays carry the same versions as Fedora and ALARM.

## Check it works

```sh
wpctl status                       # the Mac's speaker sink should be listed
systemctl status speakersafetyd    # or speakerguardd on the MacBook Neo
```

The speakers stay quiet until the safety daemon is running. If they are silent while headphones work, check the daemon's journal with `journalctl -b -u speakersafetyd`.

## Source

- [aurora-silicon/asahi-audio](https://github.com/aurora-silicon/asahi-audio)
- [aurora-silicon/alsa-ucm-conf-asahi](https://github.com/aurora-silicon/alsa-ucm-conf-asahi)
- [aurora-silicon/speakersafetyd](https://github.com/aurora-silicon/speakersafetyd)
- [aurora-silicon/speakerguardd](https://github.com/aurora-silicon/speakerguardd)
