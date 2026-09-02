#!/usr/bin/env bash
# Compare vendored third-party files against their recorded upstream revision.
#
# A vendored copy is only trustworthy if you can tell whether it still matches
# what it claims to be. Requires network and gh.
#
# There is more than one upstream now, so the revision is read from the NOTICE
# entry that names the upstream rather than from the first Revision line in the
# file. A single hardcoded revision would have silently checked the caveman
# skill against the karpathy revision and reported a fetch error as drift.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v gh >/dev/null 2>&1 || { echo "gh not installed" >&2; exit 1; }

# Revision recorded in NOTICE for one upstream. Blocks are "Upstream:" followed
# by "Revision:", so track the most recent Upstream seen and print the Revision
# that belongs to the one asked for.
rev_for() { # <owner/repo>
  awk -v want="$1" '
    /^Upstream:/ { slug = $2; sub(/^https:\/\/github\.com\//, "", slug) }
    /^Revision:/ { if (slug == want) { print $2; exit } }
  ' "$REPO_DIR/NOTICE"
}

drift=0
check() { # <local-path> <owner/repo> <upstream-path>
  local lp="$1" slug="$2" up="$3" rev tmp
  rev=$(rev_for "$slug")
  if [ -z "$rev" ]; then
    echo "  ERROR  $lp — no Revision recorded in NOTICE for $slug"; drift=1; return
  fi
  tmp=$(mktemp)
  if ! gh api "repos/$slug/contents/$up?ref=$rev" --jq '.content' 2>/dev/null | base64 -d > "$tmp"; then
    echo "  ERROR  $lp — could not fetch $up from $slug"; drift=1; rm -f "$tmp"; return
  fi
  if cmp -s "$REPO_DIR/$lp" "$tmp"; then
    echo "  OK     $lp"
  else
    echo "  DRIFT  $lp differs from $slug $up"; drift=1
  fi
  rm -f "$tmp"
}

KARPATHY="multica-ai/andrej-karpathy-skills"
CAVEMAN="JuliusBrussee/caveman"

for slug in "$KARPATHY" "$CAVEMAN"; do
  echo "Vendored from $slug at $(rev_for "$slug")"
done
echo ""

check "skills/karpathy-guidelines/SKILL.md" "$KARPATHY" "skills/karpathy-guidelines/SKILL.md"
check "rules/karpathy-guidelines.md"        "$KARPATHY" "CLAUDE.md"
check "rules/karpathy-guidelines.mdc"       "$KARPATHY" ".cursor/rules/karpathy-guidelines.mdc"
check "skills/caveman/SKILL.md"             "$CAVEMAN"  "skills/caveman/SKILL.md"

echo ""
for slug in "$KARPATHY" "$CAVEMAN"; do
  rev=$(rev_for "$slug")
  latest=$(gh api "repos/$slug/commits/main" --jq '.sha' 2>/dev/null || true)
  if [ -n "$latest" ] && [ "$latest" != "$rev" ]; then
    echo "$slug has moved on: $latest"
    echo "Re-vendor deliberately, then update Revision in NOTICE."
  fi
done

exit "$drift"
