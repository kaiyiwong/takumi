#!/bin/bash
# ── GIF: Convert clip to animated GIF ────────────────────────────────────────

# ── Profiles ────────────────────────────────────────────────────────────────
#
#   default  (default) — General purpose. 480px, 15fps, 256 colors.
#   slack    — Optimized for chat apps. 360px, 10fps, 128 colors, small file.
#   readme   — For GitHub README and docs. 720px, 15fps, 256 colors.
#   hq       — High quality for portfolio or Dribbble. 800px, 24fps.

apply_gif_profile() {
  local PROFILE="$1"
  case "$PROFILE" in
    default)
      GIF_WIDTH=480
      GIF_FPS=15
      GIF_COLORS=256
      GIF_SUFFIX=""
      ;;
    slack)
      GIF_WIDTH=360
      GIF_FPS=10
      GIF_COLORS=128
      GIF_SUFFIX="_slack"
      ;;
    readme)
      GIF_WIDTH=720
      GIF_FPS=15
      GIF_COLORS=256
      GIF_SUFFIX="_readme"
      ;;
    hq)
      GIF_WIDTH=800
      GIF_FPS=24
      GIF_COLORS=256
      GIF_SUFFIX="_hq"
      ;;
    *)
      echo "Unknown profile: $PROFILE"
      echo "Available: default, slack, readme, hq"
      return 1
      ;;
  esac
}

gif_file() {
  local INPUT="$1" START="$2" END="$3" PROFILE="$4"
  local WIDTH_OVERRIDE="$5"

  apply_gif_profile "$PROFILE" || return 1

  # Allow explicit width override
  local WIDTH="${WIDTH_OVERRIDE:-$GIF_WIDTH}"

  if [ ! -f "$INPUT" ]; then
    echo "Error: '$INPUT' not found"
    return 1
  fi

  local DIR BASENAME OUTPUT
  DIR="$(dirname "$INPUT")"
  BASENAME="$(basename "${INPUT%.*}")"
  OUTPUT="${DIR}/${BASENAME}${GIF_SUFFIX}.gif"

  echo "🎞️  Creating GIF: $(basename "$INPUT") [${START} → ${END}] @ ${WIDTH}px ${GIF_FPS}fps ${GIF_COLORS}col [${PROFILE}]"

  if ffmpeg -i "$INPUT" -ss "$START" -to "$END" \
    -vf "fps=${GIF_FPS},scale=${WIDTH}:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=${GIF_COLORS}[p];[s1][p]paletteuse" \
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

cmd_gif() {
  local INPUT=""
  local START=""
  local END=""
  local PROFILE="default"
  local WIDTH=""

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --profile)  PROFILE="$2"; shift 2 ;;
      --width)    WIDTH="$2"; shift 2 ;;
      --help|-h|help)
        echo "Usage: takumi gif <video> <start> <end> [options]"
        echo ""
        echo "Options:"
        echo "  --profile <name>  GIF profile (default: default)"
        echo "  --width <pixels>  Width override in pixels"
        echo ""
        echo "Profiles:"
        echo "  default  General purpose. 480px, 15fps, 256 colors. (default)"
        echo "  slack    Chat apps (Slack, Teams, Discord). 360px, 10fps, small file."
        echo "  readme   GitHub README and docs. 720px, 15fps."
        echo "  hq       Portfolio, Dribbble, presentations. 800px, 24fps."
        echo ""
        echo "Examples:"
        echo "  takumi gif video.mp4 00:00:05 00:00:10"
        echo "  takumi gif video.mp4 00:00:05 00:00:10 --profile slack"
        echo "  takumi gif video.mp4 00:00:00 00:00:03 --profile hq"
        echo "  takumi gif video.mp4 00:00:05 00:00:10 --width 320"
        return 0
        ;;
      *)
        if [ -z "$INPUT" ]; then
          INPUT="$1"
        elif [ -z "$START" ]; then
          START="$1"
        elif [ -z "$END" ]; then
          END="$1"
        elif [ -z "$WIDTH" ] && [[ "$1" =~ ^[0-9]+$ ]]; then
          # Backwards compat: positional width arg
          WIDTH="$1"
        fi
        shift
        ;;
    esac
  done

  if [ -z "$INPUT" ] || [ -z "$START" ] || [ -z "$END" ]; then
    echo "Usage: takumi gif <video> <start> <end> [--profile default|slack|readme|hq] [--width N]"
    return 1
  fi

  # Validate profile
  apply_gif_profile "$PROFILE" || return 1

  gif_file "$INPUT" "$START" "$END" "$PROFILE" "$WIDTH"
}
