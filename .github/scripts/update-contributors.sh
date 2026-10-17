#!/usr/bin/env bash
# Regenerates CONTRIBUTORS.md from merged pull requests. Needs REPO (owner/name) and GH_TOKEN.
# The page lists contributors only. Merged PR counts are printed to the job log.
set -euo pipefail

prs=$(gh pr list --repo "$REPO" --state merged --limit 1000 --json number,author)

cat > CONTRIBUTORS.md <<'HEADER'
# Contributors

People whose pull requests have been merged into this project. This file is generated automatically from merged PRs, so don't edit it by hand.

| Contributor |
| --- |
HEADER

echo "$prs" | jq -r '
  map(select(.author.is_bot | not))
  | group_by(.author.login)
  | sort_by(-length, (.[0].author.login | ascii_downcase))
  | .[]
  | "| [@\(.[0].author.login)](https://github.com/\(.[0].author.login)) |"' >> CONTRIBUTORS.md

# Counts stay in the log in case they are needed later.
echo "Merged PR counts:"
echo "$prs" | jq -r '
  map(select(.author.is_bot | not))
  | group_by(.author.login)
  | sort_by(-length, (.[0].author.login | ascii_downcase))
  | .[]
  | "  \(.[0].author.login): \(length)"'
