---
title: Hardware video encode
description: The Apple Video Encoder, ProRes and JPEG engines through V4L2, for GStreamer and FFmpeg.
---

The Aurora kernel drives the Mac's video encoder (AVE) and its separate ProRes and JPEG engines as V4L2 memory-to-memory devices. Any app that uses the V4L2 encoders can use them, and no extra package is needed.

The engines differ by chip, and on some Macs the AVE is not switched on yet. Check your Mac in [device support](/devices/) under Video encoding, ProRes encoding and JPEG encoding.

## Devices

| Driver | Formats |
| --- | --- |
| `apple-ave` | H.264 and HEVC, including HEVC Main 10 from P010 input |
| `apple-prores` | ProRes, all profiles |
| `apple-jpeg` | JPEG |

`v4l2-ctl --list-devices` shows which `/dev/videoN` each one got. The AVE has two extra controls: `video_bitrate_mode=2` with `constant_quality=N` for constant quality, and `prioritize_speed_over_quality=1` for a faster HEVC mode. H.264 ignores the speed control.

## GStreamer

```sh
gst-launch-1.0 videotestsrc num-buffers=300 ! video/x-raw,width=1920,height=1080 \
  ! v4l2h265enc extra-controls="controls,video_bitrate_mode=2,constant_quality=60" \
  ! h265parse ! mp4mux ! filesink location=out.mp4
```

`v4l2h264enc` works the same way. Add `prioritize_speed_over_quality=1` to the controls for the HEVC speed mode. JPEG uses `v4l2jpegenc`.

## FFmpeg

```sh
ffmpeg -i in.mp4 -c:v hevc_v4l2m2m out.mp4
```

`h264_v4l2m2m` and `hevc_v4l2m2m` write raw streams, `.ts` and `.mp4`. Writing `.mkv` fails with "Could not write header", because FFmpeg's V4L2 encoders don't fill in the stream header. FFmpeg can't set the quality and speed controls either. On Fedora, `ffmpeg-free` has no H.264 or HEVC, so install a full FFmpeg.

## Camera noise filter

The AVE also has a temporal noise filter. [Camera denoise](/docs/userland/camera-denoise/) uses it for the built-in camera where the kernel offers it.
