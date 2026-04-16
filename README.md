# takumi (匠)

A command-line toolkit for processing video assets. Convert, trim, caption, thumbnail, and inspect videos — one command at a time or in batch across folders.

Works on macOS, Windows, and Linux.

## Install

### macOS

```bash
brew tap kaiyiwong/tap
brew install takumi
takumi setup
```

`setup` installs ffmpeg and whisper via Homebrew.

### Windows

**Prerequisites:**

1. Install [Node.js](https://nodejs.org) (LTS recommended)
2. Install [Git for Windows](https://git-scm.com/download/win)

Then open PowerShell:

```powershell
npm install -g takumi-cli
takumi setup
```

`setup` installs ffmpeg via winget, chocolatey, or scoop (whichever is available).

### Linux

```bash
npm install -g takumi-cli
takumi setup
```

`setup` installs ffmpeg and whisper via apt, dnf, or pacman.

## Commands

| Command | Description |
|---------|-------------|
| `takumi convert <path> [crf] [max_height]` | Convert to FireTV-optimized H.264 MP4 |
| `takumi trim <video> <start> <end>` | Cut a clip between timestamps |
| `takumi cc <path> [lang] [model] [format]` | Generate captions using Whisper |
| `takumi thumb <path> [timestamp]` | Extract a poster image (JPG) |
| `takumi info <path>` | Show video metadata |
| `takumi gif <video> <start> <end> [width]` | Create animated GIF from a clip |
| `takumi strip <path> <audio\|video\|both>` | Extract audio/video as separate tracks |
| `takumi srt2vtt <path>` | Convert SRT subtitles to VTT |
| `takumi vtt2srt <path>` | Convert VTT subtitles to SRT |

All commands accept a single file or a folder (processes all videos recursively). Existing outputs are skipped on re-run so it's safe to retry.

### Examples

```bash
# Convert all videos in a folder for FireTV
takumi convert ./videos

# Higher quality conversion, max 720p
takumi convert ./videos 21 720

# Trim a 75-second clip
takumi trim video.mp4 00:01:30 00:02:45

# Generate Japanese captions with the large model
takumi cc ./videos ja large

# Thumbnail at a specific frame
takumi thumb video.mp4 00:00:15

# Create a GIF from a 5-second clip
takumi gif video.mp4 00:00:05 00:00:10

# Extract audio only
takumi strip video.mp4 audio

# Check resolution, codec, duration
takumi info ./videos
```

## AI Integration (MCP)

takumi includes an MCP server so AI clients like Claude Code and Kiro can use all commands as tools. No syntax to remember — just describe what you want in plain language.

```bash
takumi mcp-config
```

This prints the JSON config block. Paste it into your MCP settings:

- **Claude Code:** `~/.claude.json` or project `.mcp.json`
- **Kiro:** `.kiro/settings/mcp.json`

## Update

```bash
# Homebrew (macOS)
brew update && brew upgrade takumi

# npm (any platform)
npm update -g takumi-cli
```

## Troubleshooting

### Windows: `takumi` is not recognized

The npm global bin directory may not be in your PATH. Run this in PowerShell:

```powershell
npm prefix -g
```

If the output (e.g. `C:\Users\<you>\AppData\Roaming\npm`) is not in your PATH, add it:

```powershell
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\Users\$env:USERNAME\AppData\Roaming\npm", "User")
```

Then close and reopen PowerShell.

### Windows: bash not found

takumi needs bash to run. Git for Windows includes it. Make sure [Git for Windows](https://git-scm.com/download/win) is installed — the default installation options are fine.

### ffmpeg not found after setup

Restart your terminal. If it still doesn't work, check that ffmpeg is installed:

```bash
ffmpeg -version
```

On Windows, you can install it manually with:

```powershell
winget install --id Gyan.FFmpeg -e
```

## License

MIT
