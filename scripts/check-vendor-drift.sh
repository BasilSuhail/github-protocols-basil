#!/usr/bin/env bash
# Compare vendored third-party files against their recorded upstream revision.
#
# A vendored copy is only trustworthy if you can tell whether it still matches
# what it claims to be. Requires network and gh.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM="multica-ai/andrej-karpathy-skills"
REV=$(grep -m1 '^Revision:' "$REPO_DIR/NOTICE" | awk '{print $2}')

[ -n "$REV" ] || { echo "No Revision recorded in NOTICE" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh not installed" >&2; exit 1; }

echo "Vendored from $UPSTREAM at $REV"
echo ""

drift=0
check() { # <local-path> <upstream-path>
  local lp="$1" up="$2" tmp
  tmp=$(mktemp)
  if ! gh api "repos/$UPSTREAM/contents/$up?ref=$REV" --jq '.content' 2>/dev/null | base64 -d > "$tmp"; then
    echo "  ERROR  $lp — could not fetch $up"; drift=1; rm -f "$tmp"; return
  fi
  if cmp -s "$REPO_DIR/$lp" "$tmp"; then
    echo "  OK     $lp"
  else
    echo "  DRIFT  $lp differs from upstream $up"; drift=1
  fi
  rm -f "$tmp"
}

check "skills/karpathy-guidelines/SKILL.md" "skills/karpathy-guidelines/SKILL.md"
check "rules/karpathy-guidelines.md"        "CLAUDE.md"
check "rules/karpathy-guidelines.mdc"       ".cursor/rules/karpathy-guidelines.mdc"

echo ""
LATEST=$(gh api "repos/$UPSTREAM/commits/main" --jq '.sha' 2>/dev/null || true)
if [ -n "$LATEST" ] && [ "$LATEST" != "$REV" ]; then
  echo "Upstream has moved on: $LATEST"
  echo "Re-vendor deliberately, then update Revision in NOTICE."
fi

exit "$drift"
