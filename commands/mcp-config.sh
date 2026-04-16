#!/bin/bash
# ── MCP Config: Print MCP server configuration JSON ─────────────────────────

cmd_mcp-config() {
  local MCP_CMD
  MCP_CMD="$(command -v takumi-mcp 2>/dev/null || realpath "${SCRIPT_DIR}/bin/takumi-mcp")"

  if [ ! -x "$MCP_CMD" ]; then
    echo "❌ takumi-mcp not found."
    echo "   Reinstall takumi: brew upgrade takumi / npm install -g takumi-cli"
    return 1
  fi

  echo "── VS Code (.vscode/mcp.json) ──"
  echo ""
  cat <<EOF
{
  "servers": {
    "takumi": {
      "command": "${MCP_CMD}"
    }
  }
}
EOF

  echo ""
  echo "── Claude Code (~/.claude.json or .mcp.json) ──"
  echo ""
  cat <<EOF
{
  "mcpServers": {
    "takumi": {
      "command": "${MCP_CMD}"
    }
  }
}
EOF

  echo ""
  echo "── Kiro (.kiro/settings/mcp.json) ──"
  echo ""
  cat <<EOF
{
  "mcpServers": {
    "takumi": {
      "command": "${MCP_CMD}"
    }
  }
}
EOF
}
