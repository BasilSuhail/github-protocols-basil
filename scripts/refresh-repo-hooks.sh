#!/usr/bin/env bash
# Force-refresh git hooks in existing repositories.
#
# `git init` copies a template hook ONLY when no file of that name exists. It
# never overwrites. A repo initialised before a hook changed therefore keeps
# running the old hook forever, while the template directory looks correct and
# verify.sh reports the template as current. This script does the overwrite
# that `git init` deliberately will not.
#
# Usage:
#   bash scripts/refresh-repo-hooks.sh                 # current repo
#   bash scripts/refresh-repo-hooks.sh ~/code/a ~/code/b
#   bash scripts/refresh-repo-hooks.sh --all ~/code    # every repo under a root
set -euo pipefail

TEMPLATE="$HOME/.git-templates/hooks"
HOOKS="pre-commit commit-msg pre-push"

[ -d "$TEMPLATE" ] || { echo "No template dir at $TEMPLATE. Run install.sh first." >&2; exit 1; }

refresh_one() {
  local repo="$1" dir h
  dir=$(git -C "$repo" rev-parse --git-path hooks 2>/dev/null) || { echo "skip (not a repo): $repo"; return; }
  [ -d "$repo/$dir" ] && dir="$repo/$dir"
  mkdir -p "$dir"
  for h in $HOOKS; do
    [ -f "$TEMPLATE/$h" ] || continue
    cp "$TEMPLATE/$h" "$dir/$h"
    chmod +x "$dir/$h"
  done
  # The identifier screen is local and untracked; carry it across if present.
  if [ -f "$TEMPLATE/personal-identifiers.sh" ] && [ ! -f "$dir/personal-identifiers.sh" ]; then
    cp "$TEMPLATE/personal-identifiers.sh" "$dir/personal-identifiers.sh"
    chmod +x "$dir/personal-identifiers.sh"
  fi
  echo "refreshed: $repo"
}

if [ "${1:-}" = "--all" ]; then
  root="${2:-$HOME}"
  find "$root" -name .git -type d -maxdepth 4 \
    -not -path "*/node_modules/*" -not -path "*/Library/*" 2>/dev/null \
    | sed 's|/\.git$||' | while read -r r; do refresh_one "$r"; done
elif [ "$#" -eq 0 ]; then
  refresh_one "$(git rev-parse --show-toplevel)"
else
  for r in "$@"; do refresh_one "$r"; done
fi
