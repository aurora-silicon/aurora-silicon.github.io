---
title: Hardware video decode
description: VA-API on the Apple Video Decoder for video players and Firefox. Experimental.
---

Aurora drives the Mac's video decoder (AVD) through the standard V4L2 request interface. Two packages connect it to apps:

- `avd-fw`, open firmware for the decoder, built from source by us
- `libva-v4l2-request-avd`, the VA-API driver that players and browsers use

Both are installed by default on Fedora and available on ALARM and NixOS. Apps find the driver on their own, no environment variable needed. Encoding is separate, see [hardware video encode](/docs/userland/video-encode/).

:::caution[Experimental]
Tested on M1 Macs so far. A codec showing up in `vainfo` means the driver offered it, which is not proof every video plays correctly. Players fall back to software when something fails.
:::

## Codecs

The list depends on your kernel and Mac, check `vainfo`. Fedora's `ffmpeg-free` has no H.264 or HEVC decoder, so on Fedora, Firefox can only use the hardware for VP9 and AV1 unless you install a full FFmpeg.

## Check it works

```sh
vainfo --display drm
mpv --hwdec=vaapi video.mkv
```

In Firefox, open `about:support` and look at the Media section. Leave Firefox's media sandbox on, the driver works with it.

## Flatpak

Flatpak apps can't see the host driver. They need a matching libva extension for their runtime.

## Source

- [aurora-silicon/libva-v4l2_request](https://github.com/aurora-silicon/libva-v4l2_request)
- [aurora-silicon/avd-fw](https://github.com/aurora-silicon/avd-fw)
