#!/usr/bin/env bash
# Regenerates CONTRIBUTORS.md from merged pull requests. Needs REPO (owner/name) and GH_TOKEN.
set -euo pipefail

prs=$(gh pr list --repo "$REPO" --state merged --limit 1000 --json number,author)

cat > CONTRIBUTORS.md <<'HEADER'
# Contributors

People whose pull requests have been merged into this project. This file is generated automatically from merged PRs, so don't edit it by hand.

| Contributor | Merged PRs |
| --- | --- |
HEADER

echo "$prs" | jq -r '
  map(select(.author.is_bot | not))
  | group_by(.author.login)
  | sort_by(-length, (.[0].author.login | ascii_downcase))
  | .[]
  | "| [@\(.[0].author.login)](https://github.com/\(.[0].author.login)) | \(length) |"' >> CONTRIBUTORS.md
