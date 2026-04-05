#!/bin/bash
# ── Info: Video metadata ─────────────────────────────────────────────────────

cmd_info() {
  local INPUT="${1:-}"

  if [ -z "$INPUT" ]; then
    echo "Usage: ./takumi.sh info <file_or_folder>"
    return 1
  fi

  info_one() {
    local VIDEO="$1"
    local DURATION WIDTH HEIGHT VCODEC ACODEC BITRATE FILESIZE

    DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO" 2>/dev/null | awk '{printf "%02d:%02d:%02d", $1/3600, ($1%3600)/60, $1%60}')
    WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$VIDEO" 2>/dev/null)
    HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$VIDEO" 2>/dev/null)
    VCODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$VIDEO" 2>/dev/null)
    ACODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$VIDEO" 2>/dev/null)
    BITRATE=$(ffprobe -v error -show_entries format=bit_rate -of csv=p=0 "$VIDEO" 2>/dev/null | awk '{printf "%.0f kbps", $1/1000}')
    FILESIZE=$(du -h "$VIDEO" | cut -f1)

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📄 $(basename "$VIDEO")"
    echo "   Duration:   ${DURATION}"
    echo "   Resolution: ${WIDTH}x${HEIGHT}"
    echo "   Video:      ${VCODEC}"
    echo "   Audio:      ${ACODEC:-none}"
    echo "   Bitrate:    ${BITRATE}"
    echo "   Size:       ${FILESIZE}"
  }

  if [ -f "$INPUT" ]; then
    info_one "$INPUT"
  elif [ -d "$INPUT" ]; then
    echo "📂 Scanning: $INPUT"
    while IFS= read -r file; do
      info_one "$file"
    done < <(find_videos "$INPUT")
    echo ""
    echo "🏁 Done!"
  else
    echo "Error: '$INPUT' not found"
    return 1
  fi
}
