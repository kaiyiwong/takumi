#!/bin/bash
# ── Setup: Install dependencies ──────────────────────────────────────────────

cmd_setup() {
  echo "🔧 Installing dependencies..."
  echo ""

  local OS
  OS="$(uname -s)"

  case "$OS" in
    Darwin)
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
      ;;

    Linux)
      if command -v brew &>/dev/null; then
        echo "📦 Installing ffmpeg..."
        brew install ffmpeg 2>/dev/null || echo "   Already installed"
        echo "📦 Installing pipx..."
        brew install pipx 2>/dev/null || echo "   Already installed"
      elif command -v apt-get &>/dev/null; then
        echo "📦 Installing ffmpeg and pipx..."
        sudo apt-get update -qq && sudo apt-get install -y -qq ffmpeg pipx
      elif command -v dnf &>/dev/null; then
        echo "📦 Installing ffmpeg and pipx..."
        sudo dnf install -y ffmpeg pipx
      elif command -v pacman &>/dev/null; then
        echo "📦 Installing ffmpeg and pipx..."
        sudo pacman -S --noconfirm ffmpeg python-pipx
      else
        echo "❌ No supported package manager found. Install ffmpeg and pipx manually."
        exit 1
      fi
      pipx ensurepath 2>/dev/null
      echo "📦 Installing whisper..."
      pipx install openai-whisper 2>/dev/null || echo "   Already installed"
      ;;

    MINGW*|MSYS*|CYGWIN*)
      # Windows via Git Bash
      if command -v winget &>/dev/null; then
        echo "📦 Installing ffmpeg via winget..."
        winget install --id Gyan.FFmpeg -e --accept-source-agreements 2>/dev/null || echo "   Already installed"
      elif command -v choco &>/dev/null; then
        echo "📦 Installing ffmpeg via chocolatey..."
        choco install ffmpeg -y 2>/dev/null || echo "   Already installed"
      elif command -v scoop &>/dev/null; then
        echo "📦 Installing ffmpeg via scoop..."
        scoop install ffmpeg 2>/dev/null || echo "   Already installed"
      else
        echo "❌ No package manager found. Install ffmpeg manually:"
        echo "   https://www.ffmpeg.org/download.html"
        echo "   Or install winget, chocolatey, or scoop first."
        exit 1
      fi
      if command -v pip &>/dev/null; then
        echo "📦 Installing whisper..."
        pip install openai-whisper 2>/dev/null || echo "   Already installed"
      elif command -v pip3 &>/dev/null; then
        echo "📦 Installing whisper..."
        pip3 install openai-whisper 2>/dev/null || echo "   Already installed"
      else
        echo "⚠️  Python/pip not found. Install Python to use the cc (caption) command:"
        echo "   https://www.python.org/downloads/"
      fi
      ;;

    *)
      echo "❌ Unsupported OS: $OS"
      exit 1
      ;;
  esac

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
