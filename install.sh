#!/usr/bin/env bash
# GitHub Protocols — Installer
# Usage: bash install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Installing GitHub Protocols from: $SCRIPT_DIR"
echo ""

# 1. Global git config
echo "1. Setting global git config..."
git config --global user.email "BasilSuhail@users.noreply.github.com"
git config --global user.name "Basil Suhail"
git config --global init.templateDir "~/.git-templates"
git config --global push.default current
git config --global push.autoSetupRemote true
git config --global pull.rebase true
git config --global commit.cleanup strip
git config --global branch.sort -committerdate
echo "   Done."

# 2. Git hook templates
echo "2. Installing git hook templates..."
mkdir -p ~/.git-templates/hooks
cp "$SCRIPT_DIR/hooks/git-templates/pre-commit" ~/.git-templates/hooks/pre-commit
cp "$SCRIPT_DIR/hooks/git-templates/pre-push" ~/.git-templates/hooks/pre-push
chmod +x ~/.git-templates/hooks/pre-commit ~/.git-templates/hooks/pre-push
echo "   Done."

# 3. Claude Code hooks (if ~/.claude exists)
if [ -d "$HOME/.claude" ]; then
  echo "3. Installing Claude Code hooks..."
  mkdir -p ~/.claude/hooks
  cp "$SCRIPT_DIR/hooks/claude-code/git-commit-guard.sh" ~/.claude/hooks/
  cp "$SCRIPT_DIR/hooks/claude-code/git-push-guard.sh" ~/.claude/hooks/
  cp "$SCRIPT_DIR/hooks/claude-code/self-review-gate.sh" ~/.claude/hooks/
  chmod +x ~/.claude/hooks/git-*.sh ~/.claude/hooks/self-*.sh
  echo "   Done. (Add hooks to ~/.claude/settings.json manually — see docs/INSTALLATION.md)"
else
  echo "3. Skipping Claude Code hooks (~/.claude not found)"
fi

# 4. Universal agent rules
echo "4. Installing universal agent rules..."
mkdir -p ~/.agents/rules
cp "$SCRIPT_DIR/rules/"*.md ~/.agents/rules/
echo "   Done."

# 5. Codex rules (if ~/.codex exists)
if [ -d "$HOME/.codex" ]; then
  echo "5. Installing Codex rules..."
  mkdir -p ~/.codex/rules
  cp "$SCRIPT_DIR/rules/"*.md ~/.codex/rules/
  cp "$SCRIPT_DIR/AGENTS.md" ~/.codex/AGENTS.md
  echo "   Done."
else
  echo "5. Skipping Codex rules (~/.codex not found)"
fi

# 6. Gitleaks check
echo "6. Checking Gitleaks..."
if command -v gitleaks &>/dev/null; then
  echo "   Gitleaks $(gitleaks version) already installed."
else
  echo "   Gitleaks not found. Install with: brew install gitleaks"
fi

echo ""
echo "Installation complete. Run 'bash verify.sh' to validate."
