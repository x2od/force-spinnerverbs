#!/usr/bin/env bash
# Runs from the workflow_run comment workflow. It checks out the default branch, so the
# validator is trusted code. PR content is only read as data (git objects), never executed.
# Posts one comment per PR, updated in place on every run.
set -uo pipefail

MARKER='<!-- spinner-verb-validation -->'

# Match on the head commit. The commits/{sha}/pulls endpoint misses PRs from forks.
pr=$(gh api --paginate "repos/$REPO/pulls?state=open&per_page=100" --jq ".[] | select(.head.sha == \"$HEAD_SHA\") | .number" | head -n 1)
if [ -z "$pr" ]; then
  echo "No open PR for $HEAD_SHA; nothing to comment on."
  exit 0
fi

git fetch --quiet origin "refs/pull/$pr/head" || { echo "Could not fetch PR #$pr"; exit 1; }
if [ "$(git rev-parse FETCH_HEAD)" != "$HEAD_SHA" ]; then
  echo "PR #$pr has moved past $HEAD_SHA; a newer run will comment instead."
  exit 0
fi

base_sha=$(gh api "repos/$REPO/pulls/$pr" --jq '.base.sha')
report=$(mktemp)
BASE_SHA="$base_sha" HEAD_SHA="$HEAD_SHA" REPORT_FILE="$report" \
  bash .github/scripts/validate-spinner-verbs.sh > /dev/null 2>&1
status=$?

body=$(mktemp)
{
  echo "$MARKER"
  if [ "$status" -eq 0 ]; then
    echo "### ✅ Spinner verb check passed"
    echo
    echo "Every commit in this PR that touches \`forceSpinning.json\` follows the rules."
  else
    echo "### ❌ Spinner verb check failed"
    echo
    echo "Fix the problems below and push again. The full rules are in [CONTRIBUTING.md](https://github.com/$REPO/blob/main/CONTRIBUTING.md)."
    echo
    cat "$report"
  fi
  echo
  echo "Checked \`${HEAD_SHA:0:7}\` against \`${base_sha:0:7}\` · [Workflow run]($RUN_URL)"
} > "$body"

id=$(gh api "repos/$REPO/issues/$pr/comments" --paginate \
  --jq '.[] | select(.user.login == "github-actions[bot]" and (.body | contains("spinner-verb-validation"))) | .id' | head -n 1)
if [ -n "$id" ]; then
  gh api -X PATCH "repos/$REPO/issues/comments/$id" -F "body=@$body" --silent
  echo "Updated comment on PR #$pr."
else
  gh api -X POST "repos/$REPO/issues/$pr/comments" -F "body=@$body" --silent
  echo "Posted comment on PR #$pr."
fi
