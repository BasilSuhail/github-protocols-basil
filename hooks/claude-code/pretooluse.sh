#!/usr/bin/env bash
# Claude Code PreToolUse adapter.
#
# Claude Code pipes JSON on stdin:
#   {"tool_name":"Bash","tool_input":{"command":"..."}}
# It does NOT set CLAUDE_TOOL_NAME / CLAUDE_TOOL_INPUT. Reading those env vars
# is what silently disabled the previous generation of these hooks.
#
# Exit 0 = allow, exit 2 = block and show stderr to the agent.

set -uo pipefail

PROTOCOL_LIB="${PROTOCOL_LIB:-$HOME/.agents/lib/rules.sh}"
if [ ! -f "$PROTOCOL_LIB" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROTOCOL_LIB="$SCRIPT_DIR/../../lib/rules.sh"
fi
if [ ! -f "$PROTOCOL_LIB" ]; then
  echo "BLOCKED: protocol rule engine not found. Run install.sh." >&2
  exit 2
fi
# shellcheck source=/dev/null
. "$PROTOCOL_LIB"

PAYLOAD=$(cat)

if command -v jq >/dev/null 2>&1; then
  TOOL_NAME=$(printf '%s' "$PAYLOAD" | jq -r '.tool_name // empty')
  COMMAND=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.command // empty')
else
  TOOL_NAME=$(printf '%s' "$PAYLOAD" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null)
  COMMAND=$(printf '%s' "$PAYLOAD" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)
fi

[ "$TOOL_NAME" = "Bash" ] || exit 0
[ -n "$COMMAND" ] || exit 0

if ! protocol_check_cmd "$COMMAND"; then
  echo "" >&2
  echo "Protocol violation. Rules: GITHUB-RULES.md. Do not work around this — fix the cause." >&2
  exit 2
fi
exit 0
