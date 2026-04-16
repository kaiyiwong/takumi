# takumi (匠)

The craftsman's toolkit for shaping video assets.

## Install

```bash
brew tap kaiyiwong/tap
brew install takumi
```

This installs `takumi` globally. Run `takumi setup` once to install dependencies (ffmpeg, whisper).

```bash
takumi setup
```

### Web UI (optional)

If you prefer a visual interface over the terminal:

```bash
takumi ui
```

Opens a browser-based UI where you can browse for files, pick commands from a menu, and see real-time output. Requires Node.js.

### MCP Server (Claude Code, Kiro, etc.)

takumi includes an MCP server so AI clients can use all commands as tools.

```bash
takumi mcp-config
```

This prints the JSON config block. Paste it into your MCP settings file:

- **Claude Code:** `~/.claude.json` or project `.mcp.json`
- **Kiro:** `.kiro/settings/mcp.json`

Then just talk naturally — "convert these for FireTV", "generate Japanese captions for this folder".

### Web UI (optional)

If you prefer a visual interface over the terminal:

```bash
takumi ui
```

Opens a browser-based UI where you can browse for files, pick commands from a menu, and see real-time output. Requires Node.js (installed with most dev setups).

## Commands

### Generate Captions

```bash
takumi cc video.mp4              # auto-detect language
takumi cc ./videos ja            # Japanese, all videos in folder
takumi cc ./videos en large vtt  # English, large model, VTT format
```

Options: `[language]` `[model: tiny|base|small|medium|large]` `[format: srt|vtt]`

### Convert to FireTV MP4

```bash
takumi convert video.mp4         # single file
takumi convert ./videos          # batch folder
takumi convert ./videos 21       # higher quality (CRF 21)
takumi convert ./videos 23 720   # max 720p
```

Outputs H.264 High Profile MP4 with mod16 dimensions, AAC audio, faststart flag. Auto-detects 16:9 vs 4:3 aspect ratio.

Options: `[crf: 18-28, default 23]` `[max_height: default 1080]`

### Trim Clip

```bash
takumi trim video.mp4 00:01:30 00:02:45
```

Cuts a segment between two timestamps. Uses stream copy (no re-encoding) so it's fast.

### Extract Thumbnail

```bash
takumi thumb video.mp4           # frame at 00:00:01
takumi thumb video.mp4 00:00:15  # frame at specific time
takumi thumb ./videos            # all videos in folder
```

Extracts a high-quality JPG poster image at the video's native resolution.

Options: `[timestamp: default 00:00:01]`

### Video Info

```bash
takumi info video.mp4            # single file
takumi info ./videos             # all videos in folder
```

Shows duration, resolution, codecs, bitrate, and file size.

### Create GIF

```bash
takumi gif video.mp4 00:00:05 00:00:10       # 480px wide (default)
takumi gif video.mp4 00:00:05 00:00:10 320   # 320px wide
```

Creates an optimized animated GIF from a clip. Uses palette generation for better colors.

Options: `[width: default 480]`

### Strip Audio/Video

```bash
takumi strip video.mp4 audio     # extract audio only (.m4a)
takumi strip video.mp4 video     # extract video only, no audio
takumi strip video.mp4 both      # extract both as separate files
takumi strip ./videos both       # batch folder
```

Uses stream copy (no re-encoding).

### Convert SRT to VTT

```bash
takumi srt2vtt subtitle.srt      # single file
takumi srt2vtt ./videos          # all SRTs in folder
```

### Convert VTT to SRT

```bash
takumi vtt2srt subtitle.vtt      # single file
takumi vtt2srt ./videos          # all VTTs in folder
```

## Notes

- All commands support single files or folders (recursive)
- Existing outputs are skipped on re-run (safe to retry)
- Converted videos get a `_firetv` suffix
- Captions are saved next to the source video

## Update

```bash
brew update && brew upgrade takumi
```
