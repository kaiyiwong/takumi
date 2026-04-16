#!/bin/bash
# ── Convert: Video conversion with profile presets ──────────────────────────

# ── Profiles ────────────────────────────────────────────────────────────────
#
#   web     (default) — Web-optimized MP4. Plays everywhere.
#   firetv  — FireTV-optimized H.264 MP4. High Profile, mod16 dimensions.
#   small   — Compressed for email, Slack, low bandwidth. 720p, higher CRF.
#   hq      — High quality for portfolio or client delivery. Low CRF.

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

apply_profile() {
  local PROFILE="$1"
  case "$PROFILE" in
    web)
      PROFILE_CRF=23
      PROFILE_MAX_H=1080
      PROFILE_LEVEL=""
      PROFILE_PROFILE="main"
      PROFILE_SUFFIX="_web"
      PROFILE_MOD16=false
      PROFILE_AUDIO_BITRATE="128k"
      ;;
    firetv)
      PROFILE_CRF=23
      PROFILE_MAX_H=1080
      PROFILE_LEVEL="4.0"
      PROFILE_PROFILE="high"
      PROFILE_SUFFIX="_firetv"
      PROFILE_MOD16=true
      PROFILE_AUDIO_BITRATE="128k"
      ;;
    small)
      PROFILE_CRF=28
      PROFILE_MAX_H=720
      PROFILE_LEVEL=""
      PROFILE_PROFILE="main"
      PROFILE_SUFFIX="_small"
      PROFILE_MOD16=false
      PROFILE_AUDIO_BITRATE="96k"
      ;;
    hq)
      PROFILE_CRF=18
      PROFILE_MAX_H=2160
      PROFILE_LEVEL=""
      PROFILE_PROFILE="high"
      PROFILE_SUFFIX="_hq"
      PROFILE_MOD16=false
      PROFILE_AUDIO_BITRATE="192k"
      ;;
    *)
      echo "Unknown profile: $PROFILE"
      echo "Available: web, firetv, small, hq"
      return 1
      ;;
  esac
}

convert_file() {
  local VIDEO="$1" CRF="$2" MAX_H="$3" PROFILE="$4"

  apply_profile "$PROFILE" || return 1

  # Allow explicit overrides
  CRF="${CRF:-$PROFILE_CRF}"
  MAX_H="${MAX_H:-$PROFILE_MAX_H}"

  local DIR BASENAME OUTPUT
  DIR="$(dirname "$VIDEO")"
  BASENAME="$(basename "${VIDEO%.*}")"
  OUTPUT="${DIR}/${BASENAME}${PROFILE_SUFFIX}.mp4"

  if [ -f "$OUTPUT" ]; then
    echo "⏭️  Skipping (output exists): $(basename "$VIDEO")"
    return 0
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎬 Processing: $(basename "$VIDEO") [${PROFILE}]"

  local SRC_W SRC_H
  SRC_W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$VIDEO" 2>/dev/null)
  SRC_H=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$VIDEO" 2>/dev/null)

  if [ -z "$SRC_W" ] || [ -z "$SRC_H" ]; then
    echo "❌ Could not read dimensions: $(basename "$VIDEO")"
    return 1
  fi

  local SCALE_FILTER
  if [ "$PROFILE_MOD16" = true ]; then
    local TARGET TGT_W TGT_H
    TARGET=$(get_best_mod16 "$SRC_W" "$SRC_H" "$MAX_H")
    TGT_W="${TARGET%%:*}"
    TGT_H="${TARGET##*:}"
    SCALE_FILTER="scale=${TGT_W}:${TGT_H}"
    echo "   ${SRC_W}x${SRC_H} → ${TGT_W}x${TGT_H} (mod16) | CRF: $CRF"
  else
    SCALE_FILTER="scale=-2:'min(${MAX_H},ih)'"
    echo "   ${SRC_W}x${SRC_H} → max ${MAX_H}p | CRF: $CRF"
  fi

  local LEVEL_FLAGS=""
  if [ -n "$PROFILE_LEVEL" ]; then
    LEVEL_FLAGS="-level $PROFILE_LEVEL"
  fi

  if ffmpeg -i "$VIDEO" \
    -c:v libx264 -preset slow -crf "$CRF" \
    -profile:v "$PROFILE_PROFILE" $LEVEL_FLAGS -pix_fmt yuv420p \
    -vf "$SCALE_FILTER" \
    -c:a aac -b:a "$PROFILE_AUDIO_BITRATE" -ac 2 -ar 44100 \
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
  local INPUT=""
  local PROFILE="web"
  local CRF=""
  local MAX_H=""

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --profile)  PROFILE="$2"; shift 2 ;;
      --crf)      CRF="$2"; shift 2 ;;
      --max)      MAX_H="$2"; shift 2 ;;
      --help|-h|help)
        echo "Usage: takumi convert <file_or_folder> [options]"
        echo ""
        echo "Options:"
        echo "  --profile <name>  Conversion profile (default: web)"
        echo "  --crf <value>     Quality override (18-28, lower = better)"
        echo "  --max <height>    Max height in pixels"
        echo ""
        echo "Profiles:"
        echo "  web      Web-optimized MP4. Plays everywhere. (default)"
        echo "  firetv   FireTV-optimized. High Profile, mod16 dimensions."
        echo "  small    Compressed for email/Slack. 720p, smaller file."
        echo "  hq       High quality for portfolio or client delivery."
        echo ""
        echo "Examples:"
        echo "  takumi convert video.mp4"
        echo "  takumi convert ./videos --profile firetv"
        echo "  takumi convert ./videos --profile small"
        echo "  takumi convert video.mp4 --crf 21 --max 720"
        return 0
        ;;
      *)
        if [ -z "$INPUT" ]; then
          INPUT="$1"
        fi
        shift
        ;;
    esac
  done

  if [ -z "$INPUT" ]; then
    echo "Usage: takumi convert <file_or_folder> [--profile web|firetv|small|hq] [--crf N] [--max N]"
    return 1
  fi

  # Validate profile
  apply_profile "$PROFILE" || return 1

  if [ -f "$INPUT" ]; then
    convert_file "$INPUT" "$CRF" "$MAX_H" "$PROFILE"
  elif [ -d "$INPUT" ]; then
    echo "📂 Scanning: $INPUT"
    echo "⚙️  Profile: $PROFILE | CRF: ${CRF:-$PROFILE_CRF} | Max: ${MAX_H:-$PROFILE_MAX_H}p"
    while IFS= read -r file; do
      convert_file "$file" "$CRF" "$MAX_H" "$PROFILE"
    done < <(find_videos "$INPUT" "$PROFILE_SUFFIX")
    echo ""
    echo "🏁 Done!"
  else
    echo "Error: '$INPUT' not found"
    return 1
  fi
}
