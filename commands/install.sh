#!/bin/bash
# ── Install: Make takumi available globally ──────────────────────────────────

cmd_install() {
  local INSTALL_DIR="/usr/local/bin"
  local LINK_NAME="takumi"
  local TAKUMI_PATH
  TAKUMI_PATH="$(realpath "${SCRIPT_DIR}/takumi.sh")"

  if [ -L "${INSTALL_DIR}/${LINK_NAME}" ]; then
    local EXISTING
    EXISTING="$(readlink "${INSTALL_DIR}/${LINK_NAME}")"
    if [ "$EXISTING" = "$TAKUMI_PATH" ]; then
      echo "✅ Already installed: ${INSTALL_DIR}/${LINK_NAME} → ${TAKUMI_PATH}"
      return 0
    fi
    echo "⚠️  Existing link points to: $EXISTING"
    echo "   Updating to: $TAKUMI_PATH"
  elif [ -f "${INSTALL_DIR}/${LINK_NAME}" ]; then
    echo "❌ ${INSTALL_DIR}/${LINK_NAME} already exists and is not a symlink."
    echo "   Remove it manually if you want to proceed."
    return 1
  fi

  echo "🔗 Linking: ${INSTALL_DIR}/${LINK_NAME} → ${TAKUMI_PATH}"

  if ln -sf "$TAKUMI_PATH" "${INSTALL_DIR}/${LINK_NAME}" 2>/dev/null; then
    echo "✅ Installed! You can now run 'takumi' from anywhere."
  else
    echo "⚠️  Permission denied. Trying with sudo..."
    if sudo ln -sf "$TAKUMI_PATH" "${INSTALL_DIR}/${LINK_NAME}"; then
      echo "✅ Installed! You can now run 'takumi' from anywhere."
    else
      echo "❌ Failed to install. You can manually run:"
      echo "   sudo ln -sf \"$TAKUMI_PATH\" ${INSTALL_DIR}/${LINK_NAME}"
      return 1
    fi
  fi
}
