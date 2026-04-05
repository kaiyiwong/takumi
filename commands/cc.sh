#!/bin/bash
# ── CC: Generate Closed Captions ─────────────────────────────────────────────

cc_transcribe() {
  local VIDEO="$1" LANG="$2" MODEL="$3" FORMAT="$4"
  local BASENAME="${VIDEO%.*}"
  local AUDIO="${BASENAME}_audio.wav"
  local OUTPUT="${BASENAME}.${FORMAT}"

  if [ -f "$OUTPUT" ]; then
    echo "⏭️  Skipping (caption exists): $(basename "$VIDEO")"
    return 0
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎬 Processing: $(basename "$VIDEO")"

  ffmpeg -i "$VIDEO" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$AUDIO" -y -loglevel warning

  local LANG_FLAG=""
  [ -n "$LANG" ] && LANG_FLAG="--language $LANG"

  if perl -e 'alarm 1800; exec @ARGV' whisper "$AUDIO" --model "$MODEL" $LANG_FLAG --output_format "$FORMAT" --output_dir "$(dirname "$VIDEO")" 2>&1; then
    local WHISPER_OUTPUT="${BASENAME}_audio.${FORMAT}"
    if [ -f "$WHISPER_OUTPUT" ] && [ "$WHISPER_OUTPUT" != "$OUTPUT" ]; then
      mv "$WHISPER_OUTPUT" "$OUTPUT"
    fi
    echo "✅ Created: $(basename "$OUTPUT")"
  else
    echo "❌ Failed: $(basename "$VIDEO")"
  fi

  rm -f "$AUDIO"
  sleep 2
}

cmd_cc() {
  local INPUT="${1:-}"
  local LANG="${2:-}"
  local MODEL="${3:-medium}"
  local FORMAT="${4:-srt}"

  if [ -z "$INPUT" ]; then
    echo "Usage: ./takumi.sh cc <file_or_folder> [language] [model] [format]"
    echo "  language: ja, en, etc. (empty = auto-detect)"
    echo "  model:    tiny, base, small, medium, large (default: medium)"
    echo "  format:   srt, vtt, txt, json (default: srt)"
    return 1
  fi

  if [ -f "$INPUT" ]; then
    cc_transcribe "$INPUT" "$LANG" "$MODEL" "$FORMAT"
  elif [ -d "$INPUT" ]; then
    echo "📂 Scanning: $INPUT"
    echo "🌐 Language: ${LANG:-auto} | Model: $MODEL | Format: $FORMAT"
    while IFS= read -r file; do
      cc_transcribe "$file" "$LANG" "$MODEL" "$FORMAT"
    done < <(find_videos "$INPUT")
    echo ""
    echo "🏁 Done!"
  else
    echo "Error: '$INPUT' not found"
    return 1
  fi
}
