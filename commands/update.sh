#!/bin/bash
# ── Update: Download and install latest version ──────────────────────────────

BOX_URL="https://amazoncorporate.box.com/s/f63nklfsse0yhcxq2tahzi0harppyjl9"

cmd_update() {
  local DOWNLOADS_DIR="$HOME/Downloads"
  local ZIP_NAME="takumi.zip"
  local ZIP_PATH="${DOWNLOADS_DIR}/${ZIP_NAME}"
  local INSTALL_DIR="${SCRIPT_DIR}"

  echo "🔄 Updating takumi..."
  echo ""

  # Remove old zip if present
  rm -f "$ZIP_PATH"

  # Open Box link in browser
  echo "📦 Opening download link in your browser..."
  open "$BOX_URL"

  echo ""
  echo "   1. Download the zip file from Box"
  echo "   2. It should save to ~/Downloads/${ZIP_NAME}"
  echo ""
  read -rp "   Press Enter once the download is complete..."

  # Look for the zip
  if [ ! -f "$ZIP_PATH" ]; then
    # Try common variations
    local FOUND=""
    for f in "${DOWNLOADS_DIR}"/takumi*.zip; do
      if [ -f "$f" ]; then
        FOUND="$f"
        break
      fi
    done

    if [ -n "$FOUND" ]; then
      ZIP_PATH="$FOUND"
    else
      echo "❌ Could not find ${ZIP_NAME} in ~/Downloads"
      echo "   Download it manually and run: takumi update"
      return 1
    fi
  fi

  echo ""
  echo "📂 Found: $(basename "$ZIP_PATH")"
  echo "   Installing to: ${INSTALL_DIR}"

  # Extract to temp dir first
  local TMP_DIR
  TMP_DIR=$(mktemp -d)

  if ! unzip -qo "$ZIP_PATH" -d "$TMP_DIR" 2>/dev/null; then
    echo "❌ Failed to extract zip"
    rm -rf "$TMP_DIR"
    return 1
  fi

  # Copy new files over existing install
  cp -f "${TMP_DIR}/takumi.sh" "$INSTALL_DIR/" 2>/dev/null
  cp -rf "${TMP_DIR}/commands/" "$INSTALL_DIR/" 2>/dev/null
  cp -rf "${TMP_DIR}/ui/" "$INSTALL_DIR/" 2>/dev/null
  cp -f "${TMP_DIR}/README.md" "$INSTALL_DIR/" 2>/dev/null

  # Copy steering file if present
  if [ -f "${TMP_DIR}/.kiro/steering/takumi.md" ]; then
    mkdir -p "${INSTALL_DIR}/.kiro/steering"
    cp -f "${TMP_DIR}/.kiro/steering/takumi.md" "${INSTALL_DIR}/.kiro/steering/"
  fi

  # Ensure executable
  chmod +x "${INSTALL_DIR}/takumi.sh" "${INSTALL_DIR}/commands/"*.sh 2>/dev/null

  # Reinstall UI dependencies if needed
  if [ -f "${INSTALL_DIR}/ui/package.json" ] && command -v npm &>/dev/null; then
    echo "📦 Updating UI dependencies..."
    npm install --prefix "${INSTALL_DIR}/ui" --silent 2>/dev/null
  fi

  # Clean up
  rm -rf "$TMP_DIR"
  rm -f "$ZIP_PATH"

  echo ""
  echo "✅ Updated! Run 'takumi help' to see what's new."
}
