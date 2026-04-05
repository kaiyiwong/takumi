#!/bin/bash
# ── Thumbnail: Extract poster frame ─────────────────────────────────────────

cmd_thumb() {
  local INPUT="${1:-}"
  local TIME="${2:-00:00:01}"

  if [ -z "$INPUT" ]; then
    echo "Usage: ./takumi.sh thumb <file_or_folder> [timestamp]"
    echo "  timestamp: HH:MM:SS (default: 00:00:01)"
    echo "  Example:   ./takumi.sh thumb video.mp4 00:00:15"
    return 1
  fi

  thumb_extract() {
    local VIDEO="$1" TS="$2"
    local DIR BASENAME OUTPUT
    DIR="$(dirname "$VIDEO")"
    BASENAME="$(basename "${VIDEO%.*}")"
    OUTPUT="${DIR}/${BASENAME}_poster.jpg"

    if [ -f "$OUTPUT" ]; then
      echo "⏭️  Skipping (poster exists): $(basename "$VIDEO")"
      return 0
    fi

    echo "🖼️  Extracting: $(basename "$VIDEO") @ ${TS}"

    if ffmpeg -i "$VIDEO" -ss "$TS" -vframes 1 \
      -q:v 2 \
      -y -loglevel warning \
      "$OUTPUT" 2>&1; then
      echo "✅ Created: $(basename "$OUTPUT")"
    else
      echo "❌ Failed: $(basename "$VIDEO")"
      rm -f "$OUTPUT"
    fi
  }

  if [ -f "$INPUT" ]; then
    thumb_extract "$INPUT" "$TIME"
  elif [ -d "$INPUT" ]; then
    echo "📂 Extracting thumbnails in: $INPUT (@ ${TIME})"
    while IFS= read -r file; do
      thumb_extract "$file" "$TIME"
    done < <(find_videos "$INPUT")
    echo ""
    echo "🏁 Done!"
  else
    echo "Error: '$INPUT' not found"
    return 1
  fi
}
