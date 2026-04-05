#!/bin/bash
# ── Setup: Install dependencies ──────────────────────────────────────────────

cmd_setup() {
  echo "🔧 Installing dependencies..."
  echo ""

  OS="$(uname -s)"

  if [ "$OS" = "Darwin" ]; then
    if ! command -v brew &>/dev/null; then
      echo "❌ Homebrew not found. Install from https://brew.sh"
      exit 1
    fi

    echo "📦 Installing ffmpeg..."
    brew install ffmpeg 2>/dev/null || echo "   Already installed"

    echo "📦 Installing pipx..."
    brew install pipx 2>/dev/null || echo "   Already installed"

  elif [ "$OS" = "Linux" ]; then
    if command -v apt-get &>/dev/null; then
      echo "📦 Installing ffmpeg..."
      sudo apt-get update -qq && sudo apt-get install -y -qq ffmpeg pipx
    elif command -v dnf &>/dev/null; then
      echo "📦 Installing ffmpeg..."
      sudo dnf install -y ffmpeg pipx
    elif command -v pacman &>/dev/null; then
      echo "📦 Installing ffmpeg..."
      sudo pacman -S --noconfirm ffmpeg python-pipx
    else
      echo "❌ Unsupported package manager. Install ffmpeg and pipx manually."
      exit 1
    fi

  else
    echo "❌ Unsupported OS: $OS"
    exit 1
  fi

  pipx ensurepath 2>/dev/null

  echo "📦 Installing whisper..."
  pipx install openai-whisper 2>/dev/null || echo "   Already installed"

  echo ""
  echo "✅ All set! Restart your terminal if whisper isn't found."
}
