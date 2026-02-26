#!/usr/bin/env bash
set -euo pipefail

# Provisions a GitHub repo created from the typescript-project template.
# Applies repo settings, branch rulesets, and tag rulesets that templates don't carry over.
#
# Usage:
#   scripts/provision-repo.sh                  # auto-detects repo from git remote
#   scripts/provision-repo.sh owner/repo       # explicit repo

REPO="${1:-}"

if [[ -z "$REPO" ]]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null) || {
    echo "Error: could not detect repo. Pass owner/repo as argument." >&2
    exit 1
  }
fi

echo "Provisioning $REPO ..."

# ── Repo settings ──────────────────────────────────────────────────────────────
echo "  Setting merge strategy (merge-only) and auto-merge ..."
gh api "repos/$REPO" -X PATCH --silent \
  -f allow_merge_commit=true \
  -f allow_squash_merge=false \
  -f allow_rebase_merge=false \
  -f allow_auto_merge=true

# ── Branch ruleset: Protect main ───────────────────────────────────────────────
echo "  Creating branch ruleset: Protect main ..."
gh api "repos/$REPO/rulesets" -X POST --silent --input - <<'JSON'
{
  "name": "Protect main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "bypass_actors": [
    {
      "actor_id": 5,
      "actor_type": "RepositoryRole",
      "bypass_mode": "pull_request"
    }
  ],
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "allowed_merge_methods": ["merge"],
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_approving_review_count": 0,
        "required_review_thread_resolution": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "do_not_enforce_on_create": false,
        "strict_required_status_checks_policy": true,
        "required_status_checks": [
          { "context": "lint" },
          { "context": "typecheck" },
          { "context": "unit-tests" },
          { "context": "e2e-tests" }
        ]
      }
    },
    {
      "type": "deletion"
    }
  ]
}
JSON

# ── Tag ruleset: Immutable tags ────────────────────────────────────────────────
echo "  Creating tag ruleset: Immutable tags ..."
gh api "repos/$REPO/rulesets" -X POST --silent --input - <<'JSON'
{
  "name": "Immutable tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/tags/v*"],
      "exclude": []
    }
  },
  "bypass_actors": [],
  "rules": [
    { "type": "update" },
    { "type": "deletion" }
  ]
}
JSON

echo "Done. Rulesets applied to $REPO."
