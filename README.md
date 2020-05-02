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

Note, however, that ISO standards do **not** officially allow LPCM in MP4 containers.
For this reason, FFmpeg will happily read such containers, but [not write them][1].

## Concatenate

The `concat.sh` script joins video ... (more info later).

Basic usage:

```sh
./concat.sh input1.mp4 input2.mp4 [... inputN.mp4] output.mp4
```

Depending on your shell, you may be able to use sequence expressions in [brace
expansion][3] to simply the input filenames, such as:

```sh
./concat.sh /media/.../DCIM/100_CF12/CYQ_000{1..5}.MP4 output.mp4
```

### Environment Variables

The `concat.sh` script's behaviour can be modified by setting the following
environment variables:

* `AUDIO_FLAGS` - overrides the default audio codec; see [Audio](#Audio) below.
* `SPEED_UP` - overrides the playback speed; see [Speed-up](#Speed-up) below.

### Audio

The audio stream included in the output video file is defined by the `AUDIO_FLAGS` environment
variable. This can be set to any valid set of FFmpeg flags. However, the defaults are pretty
sensible.

The default for all non-MP4 outputs (eg Matroska) without speed-up, is `-c:a copy`, which
will copy the original PCM audio stream verbatim (ie losslessly). However, as noted in the
[background](#Background) section above, FFmpeg will not write MP4 containers with PCM
audio. For this reason, if the output is an `*.mp4` file, then `AUDIO_FLAGS` defaults to:

`-c:a aac -profile:a aac_low -b:a 384k`

That is, the audio stream will be converted (from 16-bit steroe PCM) to AAC Low Complexity
at 384 kbps. This default was chosen to match [YouTube's recommendation][2], since uploading
to YouTube is common use-case, but can of course this be overridden (by setting
`AUDIO_FLAGS`) if desired.

For example, use FLAC, do something like:

```sh
AUDIO_FLAGS='-c:a flac' ./concate.sh ... output.mkv
```

### Speed-up

The video can be sped-up by setting the `SPEED_UP` environment variable to the 'times'
speed-up you want.  For example, setting `SPEED_UP` to `8`, will result in a video that
plays 8 times faster than the original.

For example:

```sh
SPEED_UP=8 ./concat ...
```

Due to the way FFmpeg filters work, the speed-up only works in powers of two, so if
`SPEED_UP` is set to something other than a power of two, the nearest power of two will
be used instead. For example, if `SPEED_UP` is set to `5`, then the resulting video will
be four times faster, since 4 is nearest power of two to 5.

Also note, that since speeding up the audio (while keeping the original pitch) requires
re-encoding the audio, lossless audio is not possible in this mode.  In this case the
script defaults to AAC (the same default specified for MP4 output in the [Audio](#Audio)
secition above) though a lossless output codec, such as LPCM, can still be specified
by the `AUDIO_FLAGS` variable if desired.


[1]: https://trac.ffmpeg.org/ticket/3818
[2]: https://support.google.com/youtube/answer/1722171?hl=en
[3]: https://www.gnu.org/software/bash/manual/html_node/Brace-Expansion.html#Brace-Expansion
[Cycliq]: https://cycliq.com/
