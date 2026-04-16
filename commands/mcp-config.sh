#!/bin/bash
# ── MCP Config: Print MCP server configuration JSON ─────────────────────────

cmd_mcp-config() {
  local MCP_SERVER
  MCP_SERVER="$(realpath "${SCRIPT_DIR}/mcp/server.js")"

  if [ ! -f "$MCP_SERVER" ]; then
    echo "❌ MCP server not found at: ${MCP_SERVER}"
    echo "   Run 'takumi setup' first."
    return 1
  fi

  echo "── VS Code (.vscode/mcp.json) ──"
  echo ""
  cat <<EOF
{
  "servers": {
    "takumi": {
      "command": "node",
      "args": ["${MCP_SERVER}"]
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
      "command": "node",
      "args": ["${MCP_SERVER}"]
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
      "command": "node",
      "args": ["${MCP_SERVER}"]
    }
  }
}
EOF
}
