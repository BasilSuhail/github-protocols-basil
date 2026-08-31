#!/usr/bin/env bash
# Apply branch protection to main.
#
# This is the only enforcement layer an agent cannot reach. Hooks live on the
# same filesystem as the agent they constrain and can be deleted, skipped or
# simply missing on another machine. A ruleset is evaluated by GitHub, so it
# holds for every tool, every machine, and every session.
#
# Requires admin on the repository.
#
# Usage: bash scripts/apply-github-ruleset.sh [owner/repo]
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
echo "Applying protocol ruleset to $REPO"

gh api --method POST "repos/$REPO/rulesets" \
  -H "Accept: application/vnd.github+json" \
  --input - <<'JSON'
{
  "name": "protocol",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/heads/main"], "exclude": [] }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [
          { "context": "rule engine" },
          { "context": "leak scan" },
          { "context": "commit messages" }
        ]
      }
    }
  ]
}
JSON

echo ""
echo "Applied. main now requires a pull request, blocks force pushes and"
echo "deletions, and will not merge unless the protocol checks pass."
echo ""
echo "Review at: https://github.com/$REPO/settings/rules"
