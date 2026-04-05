#!/bin/bash
# ── Strip: Extract or remove audio/video tracks ─────────────────────────────

cmd_strip() {
  local INPUT="${1:-}"
  local MODE="${2:-}"

  if [ -z "$INPUT" ] || [ -z "$MODE" ]; then
    echo "Usage: ./takumi.sh strip <file_or_folder> <mode>"
    echo "  mode:"
    echo "    audio   Extract audio only (to .m4a)"
    echo "    video   Extract video only, no audio (to _noaudio.mp4)"
    echo "    both    Extract audio and video as separate files"
    echo ""
    echo "  Example:  ./takumi.sh strip video.mp4 audio"
    return 1
  fi

  strip_one() {
    local VIDEO="$1" MODE="$2"
    local DIR BASENAME
    DIR="$(dirname "$VIDEO")"
    BASENAME="$(basename "${VIDEO%.*}")"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎬 Processing: $(basename "$VIDEO")"

    # Extract audio
    if [ "$MODE" = "audio" ] || [ "$MODE" = "both" ]; then
      local AUDIO_OUT="${DIR}/${BASENAME}.m4a"
      if [ -f "$AUDIO_OUT" ]; then
        echo "⏭️  Skipping (audio exists): $(basename "$AUDIO_OUT")"
      elif ffmpeg -i "$VIDEO" -vn -c:a copy -y -loglevel warning "$AUDIO_OUT" 2>&1; then
        echo "✅ Audio: $(basename "$AUDIO_OUT")"
      else
        echo "❌ Audio extraction failed"
        rm -f "$AUDIO_OUT"
      fi
    fi

    # Extract video (no audio)
    if [ "$MODE" = "video" ] || [ "$MODE" = "both" ]; then
      local VIDEO_OUT="${DIR}/${BASENAME}_noaudio.mp4"
      if [ -f "$VIDEO_OUT" ]; then
        echo "⏭️  Skipping (video exists): $(basename "$VIDEO_OUT")"
      elif ffmpeg -i "$VIDEO" -an -c:v copy -y -loglevel warning "$VIDEO_OUT" 2>&1; then
        echo "✅ Video: $(basename "$VIDEO_OUT")"
      else
        echo "❌ Video extraction failed"
        rm -f "$VIDEO_OUT"
      fi
    fi
  }

  if [ -f "$INPUT" ]; then
    strip_one "$INPUT" "$MODE"
  elif [ -d "$INPUT" ]; then
    echo "📂 Stripping ($MODE) in: $INPUT"
    while IFS= read -r file; do
      strip_one "$file" "$MODE"
    done < <(find_videos "$INPUT")
    echo ""
    echo "🏁 Done!"
  else
    echo "Error: '$INPUT' not found"
    return 1
  fi
}
