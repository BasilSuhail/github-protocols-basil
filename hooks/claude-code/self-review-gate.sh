#!/usr/bin/env bash
# Self-Review Gate — Claude Code PreToolUse hook
# Intercepts git push and gh pr create to enforce self-review
# Outputs warnings/reminders but does not hard-block (agent handles the review)
# Exit 0 = allow with advisory, Exit 2 = block

# Fast exit for non-Bash commands
[ "$CLAUDE_TOOL_NAME" != "Bash" ] && exit 0

CMD="$CLAUDE_TOOL_INPUT"

# Check if this is a push or PR creation
IS_PUSH=false
IS_PR=false
echo "$CMD" | grep -qE 'git\s+push' && IS_PUSH=true
echo "$CMD" | grep -qE 'gh\s+pr\s+create' && IS_PR=true

# If neither, fast exit
[ "$IS_PUSH" = false ] && [ "$IS_PR" = false ] && exit 0

# === Self-Review Checklist (advisory) ===
echo "=== SELF-REVIEW GATE ==="
echo ""

# Check 1: Are there uncommitted changes?
DIRTY=$(git status --porcelain 2>/dev/null | head -5)
if [ -n "$DIRTY" ]; then
  echo "WARNING: Uncommitted changes detected:"
  echo "$DIRTY"
  echo ""
fi

# Check 2: What's the diff size?
if [ "$IS_PR" = true ]; then
  BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  [ -z "$BASE_BRANCH" ] && BASE_BRANCH="main"
  DIFF_STAT=$(git diff --stat "$BASE_BRANCH"...HEAD 2>/dev/null | tail -1)
  if [ -n "$DIFF_STAT" ]; then
    echo "PR diff: $DIFF_STAT"
  fi
fi

# Check 3: Last test run
# This is advisory — the agent should have run tests before pushing
echo "REMINDER: Verify all tests pass before pushing."
echo "REMINDER: 100% completion standard — no partial work, no 80% done."
echo "REMINDER: Self-review all changed files for correctness."
echo "==========================="

exit 0
