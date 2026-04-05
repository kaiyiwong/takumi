# takumi (匠)

The craftsman's toolkit for shaping video assets.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Setup

```bash
./takumi.sh setup
```

Installs ffmpeg, pipx, and whisper via Homebrew. Restart your terminal after.

## Commands

### Generate Captions

```bash
./takumi.sh cc video.mp4              # auto-detect language
./takumi.sh cc ./videos ja            # Japanese, all videos in folder
./takumi.sh cc ./videos en large vtt  # English, large model, VTT format
```

Options: `[language]` `[model: tiny|base|small|medium|large]` `[format: srt|vtt]`

### Convert to FireTV MP4

```bash
./takumi.sh convert video.mp4         # single file
./takumi.sh convert ./videos          # batch folder
./takumi.sh convert ./videos 21       # higher quality (CRF 21)
./takumi.sh convert ./videos 23 720   # max 720p
```

Outputs H.264 High Profile MP4 with mod16 dimensions, AAC audio, faststart flag. Auto-detects 16:9 vs 4:3 aspect ratio.

Options: `[crf: 18-28, default 23]` `[max_height: default 1080]`

### Trim Clip

```bash
./takumi.sh trim video.mp4 00:01:30 00:02:45
```

Cuts a segment between two timestamps. Uses stream copy (no re-encoding) so it's fast.

### Extract Thumbnail

```bash
./takumi.sh thumb video.mp4           # frame at 00:00:01
./takumi.sh thumb video.mp4 00:00:15  # frame at specific time
./takumi.sh thumb ./videos            # all videos in folder
```

Extracts a high-quality JPG poster image at the video's native resolution.

Options: `[timestamp: default 00:00:01]`

### Video Info

```bash
./takumi.sh info video.mp4            # single file
./takumi.sh info ./videos             # all videos in folder
```

Shows duration, resolution, codecs, bitrate, and file size.

### Create GIF

```bash
./takumi.sh gif video.mp4 00:00:05 00:00:10       # 480px wide (default)
./takumi.sh gif video.mp4 00:00:05 00:00:10 320   # 320px wide
```

Creates an optimized animated GIF from a clip. Uses palette generation for better colors.

Options: `[width: default 480]`

### Strip Audio/Video

```bash
./takumi.sh strip video.mp4 audio     # extract audio only (.m4a)
./takumi.sh strip video.mp4 video     # extract video only, no audio
./takumi.sh strip video.mp4 both      # extract both as separate files
./takumi.sh strip ./videos both       # batch folder
```

Uses stream copy (no re-encoding).

### Convert SRT to VTT

```bash
./takumi.sh srt2vtt subtitle.srt      # single file
./takumi.sh srt2vtt ./videos          # all SRTs in folder
```

### Convert VTT to SRT

```bash
./takumi.sh vtt2srt subtitle.vtt      # single file
./takumi.sh vtt2srt ./videos          # all VTTs in folder
```

## Notes

- All commands support single files or folders (recursive)
- Existing outputs are skipped on re-run (safe to retry)
- Converted videos get a `_firetv` suffix
- Captions are saved next to the source video
