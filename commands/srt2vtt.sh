#!/bin/bash
# ── SRT to VTT ───────────────────────────────────────────────────────────────

cmd_srt2vtt() {
  local INPUT="${1:-}"

  if [ -z "$INPUT" ]; then
    echo "Usage: ./takumi.sh srt2vtt <file_or_folder>"
    return 1
  fi

  convert_one() {
    local SRT="$1"
    local VTT="${SRT%.srt}.vtt"
    if [ -f "$VTT" ]; then
      echo "⏭️  Skipping: $(basename "$SRT")"
      return
    fi
    if ffmpeg -i "$SRT" "$VTT" -y -loglevel warning 2>&1; then
      echo "✅ $(basename "$SRT") → $(basename "$VTT")"
    else
      echo "❌ Failed: $(basename "$SRT")"
    fi
  }

  if [ -f "$INPUT" ]; then
    convert_one "$INPUT"
  elif [ -d "$INPUT" ]; then
    echo "📂 Converting SRT → VTT in: $INPUT"
    while IFS= read -r file; do
      convert_one "$file"
    done < <(find "$INPUT" -type f -name "*.srt" | sort)
    echo ""
    echo "🏁 Done!"
  else
    echo "Error: '$INPUT' not found"
    return 1
  fi
}
