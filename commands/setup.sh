#!/bin/bash
# ── Setup: Install dependencies ──────────────────────────────────────────────

cmd_setup() {
  echo "🔧 Installing dependencies..."
  echo ""

  if ! command -v brew &>/dev/null; then
    echo "❌ Homebrew not found. Install from https://brew.sh"
    exit 1
  fi

  echo "📦 Installing ffmpeg..."
  brew install ffmpeg 2>/dev/null || echo "   Already installed"

  echo "📦 Installing pipx..."
  brew install pipx 2>/dev/null || echo "   Already installed"
  pipx ensurepath 2>/dev/null

  echo "📦 Installing whisper..."
  pipx install openai-whisper 2>/dev/null || echo "   Already installed"

  echo ""
  echo "✅ All set! Restart your terminal if whisper isn't found."

  # Install UI dependencies if present
  local UI_DIR
  UI_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../ui"
  if [ -f "${UI_DIR}/package.json" ]; then
    echo ""
    echo "📦 Installing UI dependencies..."
    if command -v npm &>/dev/null; then
      npm install --prefix "$UI_DIR" --silent 2>/dev/null && echo "   Done" || echo "   ⚠️  npm install failed — UI may not work"
    else
      echo "   ⚠️  npm not found — install Node.js for the UI"
    fi
  fi
}
