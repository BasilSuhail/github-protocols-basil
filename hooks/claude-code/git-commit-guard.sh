#!/usr/bin/env bash
# Git Commit Guard — Claude Code PreToolUse hook
# Enforces: noreply email, no Co-Authored-By, conventional commits, no PII
# Exit 0 = allow, Exit 2 = block with message

# Fast exit for non-Bash or non-git-commit commands
[ "$CLAUDE_TOOL_NAME" != "Bash" ] && exit 0

CMD="$CLAUDE_TOOL_INPUT"
# Quick check: is this a git commit command?
echo "$CMD" | grep -qE 'git\s+commit' || exit 0

# === RULE 1: Email must be noreply ===
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

# === RULE 2: No Co-Authored-By ===
if echo "$CMD" | grep -qi 'Co-Authored-By'; then
  echo "BLOCKED: Co-Authored-By lines are prohibited. Single author only."
  exit 2
fi

# === RULE 3: No personal email in commit message ===
if echo "$CMD" | grep -qi 'basilsuhail@gmail.com'; then
  echo "BLOCKED: Personal email detected in commit. Use noreply only."
  exit 2
fi
if echo "$CMD" | grep -qi 'noreply@anthropic.com'; then
  echo "BLOCKED: AI co-author attribution detected. Single author only."
  exit 2
fi

# === RULE 4: No force flags ===
if echo "$CMD" | grep -qE -- '--no-verify|--no-gpg-sign'; then
  echo "BLOCKED: Cannot skip commit hooks. Fix the underlying issue."
  exit 2
fi

# === RULE 5: No git add -A or git add . (if combined with commit) ===
if echo "$CMD" | grep -qE 'git\s+add\s+(-A|\.)'; then
  echo "WARNING: 'git add -A' or 'git add .' detected. Stage specific files only."
  echo "This can accidentally include .env, credentials, or large binaries."
  # Warning only, not blocking — sometimes legitimate in clean repos
fi

# === RULE 6: Conventional commit format check ===
# Extract message from -m flag if present
MSG=$(echo "$CMD" | sed -n 's/.*-m\s*["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/p')
if [ -n "$MSG" ]; then
  # Check first line matches conventional commit pattern
  FIRST_LINE=$(echo "$MSG" | head -1)
  if ! echo "$FIRST_LINE" | grep -qE '^(feat|fix|refactor|docs|test|chore|ci|security|audit|session|perf|build|style|revert)(\(.+\))?(!)?:\s'; then
    echo "WARNING: Commit message doesn't follow Conventional Commits."
    echo "Format: type(scope): description"
    echo "Types: feat, fix, refactor, docs, test, chore, ci, security, audit, session"
    echo "Got: $FIRST_LINE"
    # Warning, not blocking — HEREDOC commits won't match this pattern
  fi
fi

exit 0
