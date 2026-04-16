#!/usr/bin/env bash
# GitHub Protocols — Verification Script
set -euo pipefail

PASS=0
FAIL=0

check() {
  if eval "$2" >/dev/null 2>&1; then
    echo "  PASS: $1"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $1"
    FAIL=$((FAIL + 1))
  fi
}

echo "GitHub Protocols Verification"
echo "============================="
echo ""

echo "Global Git Config:"
check "Email is noreply" "git config --global user.email | grep -q noreply.github.com"
check "Template dir set" "git config --global init.templateDir | grep -q git-templates"
check "Push default = current" "git config --global push.default | grep -q current"
check "Pull rebase = true" "git config --global pull.rebase | grep -q true"
echo ""

echo "Git Hook Templates:"
check "pre-commit exists" "test -x ~/.git-templates/hooks/pre-commit"
check "pre-push exists" "test -x ~/.git-templates/hooks/pre-push"
echo ""

echo "Claude Code Hooks:"
check "git-commit-guard.sh" "test -x ~/.claude/hooks/git-commit-guard.sh"
check "git-push-guard.sh" "test -x ~/.claude/hooks/git-push-guard.sh"
check "self-review-gate.sh" "test -x ~/.claude/hooks/self-review-gate.sh"
check "Hooks in settings.json" "test $(grep -c 'git-commit-guard\|git-push-guard\|self-review-gate' ~/.claude/settings.json 2>/dev/null) -eq 3"
echo ""

echo "Gitleaks:"
check "Gitleaks installed" "command -v gitleaks"
echo ""

echo "Universal Rules:"
check "~/.agents/rules/git-workflow.md" "test -f ~/.agents/rules/git-workflow.md"
check "~/.agents/rules/completion-standard.md" "test -f ~/.agents/rules/completion-standard.md"
check "~/.agents/rules/code-quality.md" "test -f ~/.agents/rules/code-quality.md"
echo ""

echo "Codex Rules:"
check "~/.codex/rules/ has 4 files" "test $(ls ~/.codex/rules/*.md 2>/dev/null | wc -l) -ge 4"
check "~/.codex/AGENTS.md exists" "test -f ~/.codex/AGENTS.md"
echo ""

echo "Hook Behavior Tests:"
# Test commit guard blocks Co-Authored-By
if CLAUDE_TOOL_NAME="Bash" CLAUDE_TOOL_INPUT='git commit --trailer "Co-Authored-By: X"' bash ~/.claude/hooks/git-commit-guard.sh 2>/dev/null; then
  echo "  FAIL: Commit guard should block Co-Authored-By"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: Commit guard blocks Co-Authored-By"
  PASS=$((PASS + 1))
fi

# Test push guard blocks force push
if CLAUDE_TOOL_NAME="Bash" CLAUDE_TOOL_INPUT='git push --force' bash ~/.claude/hooks/git-push-guard.sh 2>/dev/null; then
  echo "  FAIL: Push guard should block force push"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: Push guard blocks force push"
  PASS=$((PASS + 1))
fi

# Test clean commit passes
if CLAUDE_TOOL_NAME="Bash" CLAUDE_TOOL_INPUT='git commit -m "feat: test"' bash ~/.claude/hooks/git-commit-guard.sh 2>/dev/null; then
  echo "  PASS: Clean commit passes"
  PASS=$((PASS + 1))
else
  echo "  FAIL: Clean commit should pass"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "============================="
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL SYSTEMS OPERATIONAL"
else
  echo "ISSUES FOUND — review failures above"
fi
