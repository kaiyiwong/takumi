#!/bin/bash
# ── Thumbnail: Extract poster frame ─────────────────────────────────────────

# ── Profiles ────────────────────────────────────────────────────────────────
#
#   default   (default) — Original aspect ratio, no crop.
#   youtube   — 1280x720, YouTube thumbnail spec.
#   og        — 1200x630, Open Graph / social share.
#   square    — 1080x1080, Instagram / App Store.

apply_thumb_profile() {
  local PROFILE="$1"
  case "$PROFILE" in
    default)
      THUMB_SCALE=""
      THUMB_SUFFIX="_poster"
      ;;
    youtube)
      THUMB_SCALE="scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720"
      THUMB_SUFFIX="_yt"
      ;;
    og)
      THUMB_SCALE="scale=1200:630:force_original_aspect_ratio=increase,crop=1200:630"
      THUMB_SUFFIX="_og"
      ;;
    square)
      THUMB_SCALE="scale=1080:1080:force_original_aspect_ratio=increase,crop=1080:1080"
      THUMB_SUFFIX="_sq"
      ;;
    *)
      echo "Unknown profile: $PROFILE"
      echo "Available: default, youtube, og, square"
      return 1
      ;;
  esac
}

thumb_extract() {
  local VIDEO="$1" TS="$2" PROFILE="$3"

  apply_thumb_profile "$PROFILE" || return 1

  local DIR BASENAME OUTPUT
  DIR="$(dirname "$VIDEO")"
  BASENAME="$(basename "${VIDEO%.*}")"
  OUTPUT="${DIR}/${BASENAME}${THUMB_SUFFIX}.jpg"

  if [ -f "$OUTPUT" ]; then
    echo "⏭️  Skipping (exists): $(basename "$OUTPUT")"
    return 0
  fi

  echo "🖼️  Extracting: $(basename "$VIDEO") @ ${TS} [${PROFILE}]"

  local VF_ARGS=""
  if [ -n "$THUMB_SCALE" ]; then
    VF_ARGS="-vf $THUMB_SCALE"
  fi

  if ffmpeg -i "$VIDEO" -ss "$TS" -vframes 1 \
    $VF_ARGS \
    -q:v 2 \
    -y -loglevel warning \
    "$OUTPUT" 2>&1; then
    echo "✅ Created: $(basename "$OUTPUT")"
  else
    echo "❌ Failed: $(basename "$VIDEO")"
    rm -f "$OUTPUT"
  fi
}

cmd_thumb() {
  local INPUT=""
  local TIME="00:00:01"
  local PROFILE="default"

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --profile)  PROFILE="$2"; shift 2 ;;
      --help|-h|help)
        echo "Usage: takumi thumb <file_or_folder> [timestamp] [options]"
        echo ""
        echo "Options:"
        echo "  --profile <name>  Thumbnail profile (default: default)"
        echo ""
        echo "Profiles:"
        echo "  default  Original aspect ratio, no crop. (default)"
        echo "  youtube  1280x720, YouTube thumbnail spec."
        echo "  og       1200x630, Open Graph / social share."
        echo "  square   1080x1080, Instagram / App Store."
        echo ""
        echo "Examples:"
        echo "  takumi thumb video.mp4"
        echo "  takumi thumb video.mp4 00:00:15"
        echo "  takumi thumb video.mp4 00:00:15 --profile youtube"
        echo "  takumi thumb ./videos --profile og"
        return 0
        ;;
      *)
        if [ -z "$INPUT" ]; then
          INPUT="$1"
        elif [[ "$1" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
          TIME="$1"
        fi
        shift
        ;;
    esac
  done

  if [ -z "$INPUT" ]; then
    echo "Usage: takumi thumb <file_or_folder> [timestamp] [--profile default|youtube|og|square]"
    return 1
  fi

  # Validate profile
  apply_thumb_profile "$PROFILE" || return 1

  if [ -f "$INPUT" ]; then
    thumb_extract "$INPUT" "$TIME" "$PROFILE"
  elif [ -d "$INPUT" ]; then
    echo "📂 Extracting thumbnails in: $INPUT (@ ${TIME}) [${PROFILE}]"
    while IFS= read -r file; do
      thumb_extract "$file" "$TIME" "$PROFILE"
    done < <(find_videos "$INPUT")
    echo ""
    echo "🏁 Done!"
  else
    echo "Error: '$INPUT' not found"
    return 1
  fi
}
