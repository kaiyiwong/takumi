#!/bin/bash
# ── UI: Launch web interface ─────────────────────────────────────────────────

cmd_ui() {
  local UI_DIR="${SCRIPT_DIR}/ui"

  if ! command -v node &>/dev/null; then
    echo "❌ Node.js not found. Install from https://nodejs.org"
    return 1
  fi

  if [ ! -d "${UI_DIR}/node_modules" ]; then
    echo "📦 Installing UI dependencies..."
    npm install --prefix "$UI_DIR" --silent
  fi

  echo "🔧 Starting takumi UI..."
  echo "   Press Ctrl+C to stop"
  echo ""

  # Clean up any old port file
  rm -f "${UI_DIR}/.port"

  # Start server in background
  node "${UI_DIR}/server.js" &
  local PID=$!

  # Wait for server to write its port
  local PORT=""
  for i in $(seq 1 20); do
    sleep 0.25
    if [ -f "${UI_DIR}/.port" ]; then
      PORT=$(cat "${UI_DIR}/.port")
      break
    fi
  done

  if [ -n "$PORT" ]; then
    open "http://localhost:${PORT}"
  fi

  wait "$PID"
  rm -f "${UI_DIR}/.port"
}
