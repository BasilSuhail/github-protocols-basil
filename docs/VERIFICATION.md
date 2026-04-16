# Verification Guide

Run these checks to confirm everything is properly installed.

## Quick Verify Script

```bash
bash ~/github-protocols-basil/verify.sh
```

## Manual Checks

### 1. Global Git Config

```bash
git config --global user.email
# Expected: BasilSuhail@users.noreply.github.com

git config --global init.templateDir
# Expected: ~/.git-templates
```

### 2. Git Hook Templates

```bash
ls -la ~/.git-templates/hooks/
# Expected: pre-commit (executable), pre-push (executable)
```

### 3. Claude Code Hooks

```bash
ls -la ~/.claude/hooks/git-*.sh ~/.claude/hooks/self-*.sh
# Expected: 3 executable scripts

grep -c "git-commit-guard\|git-push-guard\|self-review-gate" ~/.claude/settings.json
# Expected: 3
```

### 4. Gitleaks

```bash
gitleaks version
# Expected: 8.x.x
```

### 5. Hook Tests

```bash
# Test commit guard blocks Co-Authored-By
CLAUDE_TOOL_NAME="Bash" CLAUDE_TOOL_INPUT='git commit --trailer "Co-Authored-By: X"' \
  bash ~/.claude/hooks/git-commit-guard.sh
# Expected: BLOCKED (exit code 2)

# Test push guard blocks force push
CLAUDE_TOOL_NAME="Bash" CLAUDE_TOOL_INPUT='git push --force' \
  bash ~/.claude/hooks/git-push-guard.sh
# Expected: BLOCKED (exit code 2)

# Test clean commands pass
CLAUDE_TOOL_NAME="Bash" CLAUDE_TOOL_INPUT='git commit -m "feat: add auth"' \
  bash ~/.claude/hooks/git-commit-guard.sh
# Expected: exit code 0
```

### 6. Rules Files

```bash
ls ~/.agents/rules/*.md
# Expected: 4 files including agent-style

ls ~/.codex/rules/*.md
# Expected: 4 files (mirrored)

ls ~/.codex/AGENTS.md
# Expected: exists
```

### 7. Per-Repo Hooks

```bash
# Check a specific repo
ls -la /path/to/repo/.git/hooks/pre-commit
ls -la /path/to/repo/.git/hooks/pre-push
# Expected: both exist and are executable
```
