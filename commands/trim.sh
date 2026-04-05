#!/bin/bash
# ── Trim: Cut a clip ─────────────────────────────────────────────────────────

cmd_trim() {
  local INPUT="${1:-}"
  local START="${2:-}"
  local END="${3:-}"

  if [ -z "$INPUT" ] || [ -z "$START" ] || [ -z "$END" ]; then
    echo "Usage: ./takumi.sh trim <video> <start> <end>"
    echo "  start/end: HH:MM:SS or SS format"
    echo "  Example:   ./takumi.sh trim video.mp4 00:01:30 00:02:45"
    return 1
  fi

  if [ ! -f "$INPUT" ]; then
    echo "Error: '$INPUT' not found"
    return 1
  fi

  local DIR BASENAME EXT OUTPUT
  DIR="$(dirname "$INPUT")"
  BASENAME="$(basename "${INPUT%.*}")"
  EXT="${INPUT##*.}"
  OUTPUT="${DIR}/${BASENAME}_trim.${EXT}"

  echo "✂️  Trimming: $(basename "$INPUT") [${START} → ${END}]"

  if ffmpeg -i "$INPUT" -ss "$START" -to "$END" \
    -c copy -avoid_negative_ts make_zero \
    -y -loglevel warning -stats \
    "$OUTPUT" 2>&1; then
    local OUT_SIZE
    OUT_SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "✅ Created: $(basename "$OUTPUT") (${OUT_SIZE})"
  else
    echo "❌ Failed: $(basename "$INPUT")"
    rm -f "$OUTPUT"
  fi
}
