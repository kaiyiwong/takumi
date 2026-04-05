#!/bin/bash
# ── Convert: FireTV-optimized MP4 ────────────────────────────────────────────

SIZES_16_9=("1920:1080" "1280:720" "1024:576" "768:432" "512:288" "256:144")
SIZES_4_3=("640:480" "576:432" "512:384" "448:336" "384:288" "320:240" "256:192" "192:144" "128:96")

get_best_mod16() {
  local SRC_W="$1" SRC_H="$2" MAX_H="$3"
  local RATIO
  RATIO=$(echo "$SRC_W $SRC_H" | awk '{printf "%.2f", $1/$2}')

  local SIZES
  if (( $(echo "$RATIO > 1.5" | bc -l) )); then
    SIZES=("${SIZES_16_9[@]}")
  else
    SIZES=("${SIZES_4_3[@]}")
  fi

  for SIZE in "${SIZES[@]}"; do
    local W="${SIZE%%:*}" H="${SIZE##*:}"
    if [ "$H" -le "$MAX_H" ] && [ "$H" -le "$SRC_H" ]; then
      echo "${W}:${H}"
      return
    fi
  done
  echo "${SIZES[-1]}"
}

convert_file() {
  local VIDEO="$1" CRF="$2" MAX_H="$3"
  local DIR BASENAME OUTPUT
  DIR="$(dirname "$VIDEO")"
  BASENAME="$(basename "${VIDEO%.*}")"
  OUTPUT="${DIR}/${BASENAME}${CONVERT_SUFFIX}.mp4"

  if [ -f "$OUTPUT" ]; then
    echo "⏭️  Skipping (output exists): $(basename "$VIDEO")"
    return 0
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎬 Processing: $(basename "$VIDEO")"

  local SRC_W SRC_H
  SRC_W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$VIDEO" 2>/dev/null)
  SRC_H=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$VIDEO" 2>/dev/null)

  if [ -z "$SRC_W" ] || [ -z "$SRC_H" ]; then
    echo "❌ Could not read dimensions: $(basename "$VIDEO")"
    return 1
  fi

  local TARGET TGT_W TGT_H
  TARGET=$(get_best_mod16 "$SRC_W" "$SRC_H" "$MAX_H")
  TGT_W="${TARGET%%:*}"
  TGT_H="${TARGET##*:}"

  echo "   ${SRC_W}x${SRC_H} → ${TGT_W}x${TGT_H} (mod16) | CRF: $CRF"

  if ffmpeg -i "$VIDEO" \
    -c:v libx264 -preset slow -crf "$CRF" \
    -profile:v high -level 4.0 -pix_fmt yuv420p \
    -vf "scale=${TGT_W}:${TGT_H}" -r 30 \
    -c:a aac -b:a 128k -ac 2 -ar 44100 \
    -movflags +faststart \
    -y -loglevel warning -stats \
    "$OUTPUT" 2>&1; then
    local SRC_SIZE OUT_SIZE
    SRC_SIZE=$(du -h "$VIDEO" | cut -f1)
    OUT_SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "✅ Done: $(basename "$OUTPUT") (${SRC_SIZE} → ${OUT_SIZE})"
  else
    echo "❌ Failed: $(basename "$VIDEO")"
    rm -f "$OUTPUT"
  fi
  sleep 1
}

cmd_convert() {
  local INPUT="${1:-}"
  local CRF="${2:-23}"
  local MAX_H="${3:-1080}"

  if [ -z "$INPUT" ]; then
    echo "Usage: ./takumi.sh convert <file_or_folder> [crf] [max_height]"
    echo "  crf:        18-28 (default: 23, lower = better quality)"
    echo "  max_height: max output height (default: 1080)"
    return 1
  fi

  if [ -f "$INPUT" ]; then
    convert_file "$INPUT" "$CRF" "$MAX_H"
  elif [ -d "$INPUT" ]; then
    echo "📂 Scanning: $INPUT"
    echo "⚙️  CRF: $CRF | Max: ${MAX_H}p | H.264 MP4"
    while IFS= read -r file; do
      convert_file "$file" "$CRF" "$MAX_H"
    done < <(find_videos "$INPUT" "$CONVERT_SUFFIX")
    echo ""
    echo "🏁 Done!"
  else
    echo "Error: '$INPUT' not found"
    return 1
  fi
}
