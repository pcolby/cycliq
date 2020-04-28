# Cycliq

Just some scripts for working with [Cycliq] camera videos.

## Background

Cycliq camera videos contain two streams within an MP4 container:

* Video: H264, with configurable resolution and frame-rate (eg 1920x1080, 60 FPS).
* Audio: LPCM, 16-bit, signed, little endian, 48kHz, stereo.

Just an example:

```sh
$ ffprobe /path/to/cycliq/video.mp4 2>&1 | grep Stream
    Stream #0:0(eng): Video: h264 (Main) (avc1 / 0x31637661), yuv420p(tv, bt709), 1920x1080, 28204 kb/s, 59.94 fps, 59.94 tbr, 60k tbn, 119.88 tbc (default)
    Stream #0:1(eng): Audio: pcm_s16le (sowt / 0x74776F73), 48000 Hz, 2 channels, s16, 1536 kb/s (default)
```

Note, however, that the use of LPCM in MP4 containers is **not** officially allowed.
For this reason, FFmpeg will happily read such containers, but [not write them][1].

## Concatenate

The `concat.sh` script joins video ... (more info later).

### Audio

The audio stream included in the output video file is defined by the `AUDIO_FLAGS` environment
variable. This can be set to any valid set of FFmpeg flags. However, the defaults are pretty
sensible.

The default for all non-MP4 outputs (eg Matroska), is `-c:a copy`, which will copy the
original PCM audio stream verbatim (ie losslessly). However, as noted in the [background](#Background) section above, FFmpeg will not write MP4 containers with PCM audio. For this
reason, if the output is an `*.mp4` file, then `AUDIO_FLAGS` defaults to:

`-c:a aac -profile:a aac_low -b:a 384k`

That is, the audio stream will be convert (from 16-bit steroe PCM) to AAC Low Complexity at
384 kbps. The default is chosen to match [YouTube's recommendation][2], but can of course
be overridden (by setting `AUDIO_FLAGS`) if desired.

[1]: https://trac.ffmpeg.org/ticket/3818
[2]: https://support.google.com/youtube/answer/1722171?hl=en
[Cycliq]: https://cycliq.com/