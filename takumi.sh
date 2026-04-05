#!/bin/bash
# ============================================================================
# takumi (匠) — The craftsman's toolkit for shaping video assets
# ============================================================================
# Commands:
#   cc        Generate closed captions (SRT/VTT) using Whisper
#   convert   Convert videos to FireTV-optimized H.264 MP4 (mod16)
#   trim      Cut a clip between timestamps
#   thumb     Extract poster image from video
#   info      Show video metadata
#   gif       Create animated GIF from a clip
#   strip     Extract audio/video as separate tracks
#   srt2vtt   Convert existing SRT files to VTT format
#   vtt2srt   Convert existing VTT files to SRT format
#   setup     Install all dependencies
#
# Usage:
#   ./takumi.sh <command> <file_or_folder> [options...]
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

VIDEO_EXTENSIONS="mp4|mov|avi|mkv|webm|m4v|flv|wmv|mpg|mpeg|ts"
CONVERT_SUFFIX="_firetv"

# ── Helpers ──────────────────────────────────────────────────────────────────

find_videos() {
  local DIR="$1"
  local EXCLUDE="${2:-}"
  if [ -n "$EXCLUDE" ]; then
    find "$DIR" -type f | grep -iE "\.(${VIDEO_EXTENSIONS})$" | grep -v "$EXCLUDE" | sort
  else
    find "$DIR" -type f | grep -iE "\.(${VIDEO_EXTENSIONS})$" | sort
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────

CMD="${1:-}"
shift 2>/dev/null || true

show_help() {
  echo "takumi (匠) — The craftsman's toolkit for shaping video assets"
  echo ""
  echo "Commands:"
  echo "  setup                              Install dependencies (ffmpeg, whisper)"
  echo "  cc <path> [lang] [model] [format]  Generate captions from video"
  echo "  convert <path> [crf] [max_height]  Convert to FireTV H.264 MP4"
  echo "  trim <video> <start> <end>         Cut a clip between timestamps"
  echo "  thumb <path> [timestamp]            Extract poster image (JPG)"
  echo "  info <path>                         Show video metadata"
  echo "  gif <video> <start> <end> [width]  Create animated GIF from clip"
  echo "  strip <path> <audio|video|both>    Extract audio/video tracks"
  echo "  srt2vtt <path>                     Convert SRT subtitles to VTT"
  echo "  vtt2srt <path>                     Convert VTT subtitles to SRT"
  echo ""
  echo "Examples:"
  echo "  ./takumi.sh setup"
  echo "  ./takumi.sh cc ./videos ja"
  echo "  ./takumi.sh convert ./videos 21"
  echo "  ./takumi.sh trim video.mp4 00:01:30 00:02:45"
  echo "  ./takumi.sh thumb video.mp4 00:00:15"
  echo "  ./takumi.sh info ./videos"
  echo "  ./takumi.sh gif video.mp4 00:00:05 00:00:10"
  echo "  ./takumi.sh strip video.mp4 both"
  echo "  ./takumi.sh srt2vtt ./videos"
  echo "  ./takumi.sh vtt2srt ./videos"
}

case "$CMD" in
  setup|cc|convert|srt2vtt|vtt2srt|trim|thumb|info|gif|strip)
    if [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
      source "${SCRIPT_DIR}/commands/${CMD}.sh"
      "cmd_${CMD}"
    else
      source "${SCRIPT_DIR}/commands/${CMD}.sh"
      "cmd_${CMD}" "$@"
    fi
    ;;
  help|--help|-h|"")
    show_help
    ;;
  *)
    echo "Unknown command: $CMD"
    echo "Run './takumi.sh help' for usage."
    ;;
esac
