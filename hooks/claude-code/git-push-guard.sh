#!/usr/bin/env bash
# Git Push Guard — Claude Code PreToolUse hook
# Enforces: no force push, no upstream targets, email check, no --no-verify
# Exit 0 = allow, Exit 2 = block with message

# Fast exit for non-Bash commands
[ "$CLAUDE_TOOL_NAME" != "Bash" ] && exit 0

CMD="$CLAUDE_TOOL_INPUT"
# Quick check: is this a git push command?
echo "$CMD" | grep -qE 'git\s+push' || exit 0

# === RULE 1: No force push ===
if echo "$CMD" | grep -qE -- '--force\b|-f\b|--force-with-lease'; then
  echo "BLOCKED: Force push is prohibited. Use a merge-based strategy."
  echo "If absolutely necessary, get explicit user approval first."
  exit 2
fi

# === RULE 2: No non-Basil targets ===
if echo "$CMD" | grep -qE 'git\s+push' && ! echo "$CMD" | grep -qi 'BasilSuhail'; then
  echo "WARNING: Push command does not name BasilSuhail explicitly."
  echo "Verify remote before push."
fi
if echo "$CMD" | grep -qi 'ShaheerKhawaja\|entropy-co'; then
  echo "BLOCKED: Cannot push to upstream repos."
  echo "Only use BasilSuhail forks."
  exit 2
fi

# === RULE 3: No --no-verify ===
if echo "$CMD" | grep -qE -- '--no-verify'; then
  echo "BLOCKED: Cannot skip push hooks. Fix the underlying issue."
  exit 2
fi

# === RULE 4: Email check ===
CURRENT_EMAIL=$(git config user.email 2>/dev/null)
if [ -n "$CURRENT_EMAIL" ]; then
  case "$CURRENT_EMAIL" in
    *noreply.github.com) ;; # OK
    *)
      echo "BLOCKED: git user.email is '$CURRENT_EMAIL' — must be noreply.github.com"
      echo "Fix: git config user.email 'BasilSuhail@users.noreply.github.com'"
      exit 2
      ;;
  esac
fi

# === RULE 5: gh command upstream check ===
if echo "$CMD" | grep -qE 'gh\s+(pr|issue)' && ! echo "$CMD" | grep -q '\-\-repo'; then
  echo "WARNING: gh command without --repo flag. Verify target repo is correct."
  echo "Always use --repo BasilSuhail/<repo-name> to prevent upstream leaks."
  # Warning only — some repos have correct defaults
fi

exit 0
