#!/usr/bin/env bash
# Protocol installer.
#
# Installs the rule engine plus one thin adapter per enforcement layer, then
# registers the Claude Code adapter in settings.json. Registration used to be a
# manual step in the docs, which is how three hooks stayed registered under
# names that no longer enforced anything.
#
# Usage: bash install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Installing protocols from: $SCRIPT_DIR"
echo ""

echo "1. Identity"
# Identity is not stored in this repository. It lives in an untracked config,
# because the repo is public and a real name and address are precisely what
# ID-401 to ID-404 exist to keep out of it.
CONF="$HOME/.agents/protocol.conf"
mkdir -p "$HOME/.agents"
if [ ! -f "$CONF" ]; then
  # Bootstrap from whatever git already knows, so a first run is not a form.
  EXIST_NAME=$(git config --global user.name 2>/dev/null || true)
  EXIST_EMAIL=$(git config --global user.email 2>/dev/null || true)
  EXIST_OWNER="${EXIST_EMAIL%%@*}"
  {
    echo "# Written by install.sh. Untracked, never pushed."
    echo "PROTOCOL_OWNER=\"${EXIST_OWNER:-your-github-handle}\""
    echo "PROTOCOL_NAME=\"${EXIST_NAME:-Your Name}\""
    echo "PROTOCOL_EMAIL=\"${EXIST_EMAIL:-your-github-handle@users.noreply.github.com}\""
    echo "PROTOCOL_EMAIL_SUFFIX=\"users.noreply.github.com\""
  } > "$CONF"
  echo "   created $CONF from your existing git config — review it"
fi
# shellcheck source=/dev/null
. "$CONF"

if [ -z "${PROTOCOL_OWNER:-}" ] || [ "$PROTOCOL_OWNER" = "your-github-handle" ]; then
  echo "   ERROR: set PROTOCOL_OWNER in $CONF before continuing." >&2
  exit 1
fi

echo "2. Global git config"
git config --global user.name "$PROTOCOL_NAME"
git config --global user.email "$PROTOCOL_EMAIL"
git config --global protocol.owner "$PROTOCOL_OWNER"
git config --global init.templateDir "$HOME/.git-templates"
git config --global push.default current
git config --global push.autoSetupRemote true
git config --global pull.rebase true
git config --global commit.cleanup strip
git config --global branch.sort -committerdate
echo "   done"

echo "3. Rule engine -> ~/.agents/lib/rules.sh"
mkdir -p "$HOME/.agents/lib"
cp "$SCRIPT_DIR/lib/rules.sh" "$HOME/.agents/lib/rules.sh"

# The personal-identifier screen names real people and institutions, so it is
# never tracked and never shipped. Adopt one that already exists on this
# machine; never overwrite it, and never write the example over a real one.
SCREEN="$HOME/.agents/lib/personal-identifiers.sh"
if [ ! -f "$SCREEN" ]; then
  for legacy in "$HOME/.git-templates/hooks/personal-identifiers.sh" \
                "$(git rev-parse --git-path hooks 2>/dev/null)/personal-identifiers.sh"; do
    if [ -f "$legacy" ]; then
      cp "$legacy" "$SCREEN"
      echo "   adopted existing identifier screen from $legacy"
      break
    fi
  done
fi
[ -f "$SCREEN" ] || echo "   NOTE: no identifier screen (ID-401 inactive). See lib/personal-identifiers.example.sh"
echo "   done"

echo "4. Git hook templates -> ~/.git-templates/hooks"
mkdir -p "$HOME/.git-templates/hooks"
for h in pre-commit commit-msg pre-push; do
  cp "$SCRIPT_DIR/hooks/git-templates/$h" "$HOME/.git-templates/hooks/$h"
  chmod +x "$HOME/.git-templates/hooks/$h"
done
echo "   done"

if [ -d "$HOME/.claude" ]; then
  echo "5. Claude Code adapter -> ~/.claude/hooks/pretooluse.sh"
  mkdir -p "$HOME/.claude/hooks"
  cp "$SCRIPT_DIR/hooks/claude-code/pretooluse.sh" "$HOME/.claude/hooks/pretooluse.sh"
  chmod +x "$HOME/.claude/hooks/pretooluse.sh"

  # Retire the previous generation. They read env vars Claude Code never sets.
  for stale in git-commit-guard.sh git-push-guard.sh self-review-gate.sh; do
    [ -f "$HOME/.claude/hooks/$stale" ] && rm -f "$HOME/.claude/hooks/$stale" \
      && echo "   removed stale hook: $stale"
  done

  SETTINGS="$HOME/.claude/settings.json"
  if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
    cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
    tmp=$(mktemp)
    jq '
      # Drop any registration of the retired guards, then any now-empty groups.
      (.hooks.PreToolUse //= [])
      | .hooks.PreToolUse |= map(
          .hooks |= map(select(
            (.command // "") | test("git-commit-guard|git-push-guard|self-review-gate") | not
          ))
        )
      | .hooks.PreToolUse |= map(select((.hooks | length) > 0))
      # Register the single adapter exactly once.
      | if any(.hooks.PreToolUse[]?.hooks[]?; (.command // "") | test("pretooluse\\.sh"))
        then .
        else .hooks.PreToolUse += [{
          matcher: "Bash",
          hooks: [{ type: "command", command: "bash \"$HOME/.claude/hooks/pretooluse.sh\"", timeout: 5000 }]
        }]
        end
    ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "   settings.json updated (backup written alongside it)"
  else
    echo "   NOTE: register manually in $SETTINGS under hooks.PreToolUse (matcher \"Bash\"):"
    echo '         bash "$HOME/.claude/hooks/pretooluse.sh"'
  fi
else
  echo "5. Skipping Claude Code adapter (~/.claude not found)"
fi

if [ -d "$HOME/.claude" ]; then
  echo "6. Skills -> ~/.claude/skills"
  mkdir -p "$HOME/.claude/skills"
  for skill in "$SCRIPT_DIR"/skills/*/; do
    [ -d "$skill" ] || continue
    name=$(basename "$skill")
    mkdir -p "$HOME/.claude/skills/$name"
    cp "$skill"SKILL.md "$HOME/.claude/skills/$name/SKILL.md"
    echo "   installed skill: $name"
  done
fi

if [ -d "$HOME/.cursor" ]; then
  echo "7. Cursor rules -> ~/.cursor/rules"
  mkdir -p "$HOME/.cursor/rules"
  cp "$SCRIPT_DIR/rules/"*.mdc "$HOME/.cursor/rules/" 2>/dev/null || true
  echo "   done"
fi

echo "8. Universal agent rules -> ~/.agents/rules"
mkdir -p "$HOME/.agents/rules"
cp "$SCRIPT_DIR/rules/"*.md "$HOME/.agents/rules/"
echo "   done"

if [ -d "$HOME/.codex" ]; then
  echo "9. Codex rules -> ~/.codex"
  mkdir -p "$HOME/.codex/rules"
  cp "$SCRIPT_DIR/rules/"*.md "$HOME/.codex/rules/"
  cp "$SCRIPT_DIR/AGENTS.md" "$HOME/.codex/AGENTS.md"
  echo "   done"
else
  echo "9. Skipping Codex rules (~/.codex not found)"
fi

echo "10. Tooling"
command -v gitleaks >/dev/null 2>&1 && echo "   gitleaks: $(gitleaks version 2>/dev/null)" \
  || echo "   gitleaks MISSING — brew install gitleaks"
command -v jq >/dev/null 2>&1 && echo "   jq: $(jq --version)" \
  || echo "   jq MISSING — brew install jq"

echo ""
echo "Existing repos keep their old hooks: git init copies a template hook only"
echo "when no file of that name exists, and never overwrites. Force a refresh:"
echo "  bash scripts/refresh-repo-hooks.sh            # current repo"
echo "  bash scripts/refresh-repo-hooks.sh --all ~/folders"
echo ""
echo "Now run: bash verify.sh"
