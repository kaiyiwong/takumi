#!/bin/bash
# ── VTT to SRT ───────────────────────────────────────────────────────────────

cmd_vtt2srt() {
  local INPUT="${1:-}"

  if [ -z "$INPUT" ]; then
    echo "Usage: ./takumi.sh vtt2srt <file_or_folder>"
    return 1
  fi

  convert_one() {
    local VTT="$1"
    local SRT="${VTT%.vtt}.srt"
    if [ -f "$SRT" ]; then
      echo "⏭️  Skipping: $(basename "$VTT")"
      return
    fi
    if ffmpeg -i "$VTT" "$SRT" -y -loglevel warning 2>&1; then
      echo "✅ $(basename "$VTT") → $(basename "$SRT")"
    else
      echo "❌ Failed: $(basename "$VTT")"
    fi
  }

  if [ -f "$INPUT" ]; then
    convert_one "$INPUT"
  elif [ -d "$INPUT" ]; then
    echo "📂 Converting VTT → SRT in: $INPUT"
    while IFS= read -r file; do
      convert_one "$file"
    done < <(find "$INPUT" -type f -name "*.vtt" | sort)
    echo ""
    echo "🏁 Done!"
  else
    echo "Error: '$INPUT' not found"
    return 1
  fi
}
