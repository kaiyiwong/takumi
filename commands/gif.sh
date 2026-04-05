#!/bin/bash
# ── GIF: Convert clip to animated GIF ────────────────────────────────────────

cmd_gif() {
  local INPUT="${1:-}"
  local START="${2:-}"
  local END="${3:-}"
  local WIDTH="${4:-480}"

  if [ -z "$INPUT" ] || [ -z "$START" ] || [ -z "$END" ]; then
    echo "Usage: ./takumi.sh gif <video> <start> <end> [width]"
    echo "  start/end: HH:MM:SS or SS format"
    echo "  width:     output width in px (default: 480, height auto)"
    echo "  Example:   ./takumi.sh gif video.mp4 00:00:05 00:00:10 320"
    return 1
  fi

  if [ ! -f "$INPUT" ]; then
    echo "Error: '$INPUT' not found"
    return 1
  fi

  local DIR BASENAME OUTPUT
  DIR="$(dirname "$INPUT")"
  BASENAME="$(basename "${INPUT%.*}")"
  OUTPUT="${DIR}/${BASENAME}.gif"

  echo "🎞️  Creating GIF: $(basename "$INPUT") [${START} → ${END}] @ ${WIDTH}px"

  if ffmpeg -i "$INPUT" -ss "$START" -to "$END" \
    -vf "fps=15,scale=${WIDTH}:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
    -loop 0 \
    -y -loglevel warning \
    "$OUTPUT" 2>&1; then
    local OUT_SIZE
    OUT_SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "✅ Created: $(basename "$OUTPUT") (${OUT_SIZE})"
  else
    echo "❌ Failed: $(basename "$INPUT")"
    rm -f "$OUTPUT"
  fi
}
