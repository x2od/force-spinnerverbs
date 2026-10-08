#!/usr/bin/env bash
# Validates forceSpinning.json in every commit in the pushed/PR range that touches it.
# Rules (see CONTRIBUTING.md):
#   - first four lines and last three lines match the required wrapper exactly
#   - file is valid JSON with a spinnerVerbs.verbs array
#   - each verb uses only letters, digits, and hyphens
#   - each verb starts with a capital letter (other letters are not checked for case)
#   - each verb ends in "ing"
#   - no duplicate verbs (case-insensitive)
#   - verbs are in alphabetical order (case-insensitive)
set -uo pipefail

FILE="forceSpinning.json"
ZERO="0000000000000000000000000000000000000000"
BASE_SHA="${BASE_SHA:-}"
HEAD_SHA="${HEAD_SHA:-HEAD}"
REPORT_FILE="${REPORT_FILE:-}"
errors=0

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

printf '%s\n' '{' '  "spinnerVerbs": {' '    "mode": "MODE",' '    "verbs": [' > "$tmp/expected_head"
printf '%s\n' '    ]' '  }' '}' > "$tmp/expected_tail"

fail() {
  echo "::error file=$FILE::$1"
  echo "- $1" >> "$tmp/problems.txt"
  errors=$((errors + 1))
}

check_commit() {
  local commit=$1 short
  short=$(git rev-parse --short "$commit")

  if ! git show "$commit:$FILE" > "$tmp/file.json" 2>/dev/null; then
    fail "[$short] $FILE is missing"
    return
  fi

  if ! diff -q <(head -n 4 "$tmp/file.json" | sed -E 's/"mode": "(replace|append)",/"mode": "MODE",/') "$tmp/expected_head" > /dev/null; then
    fail "[$short] first four lines must be exactly: {  /  \"spinnerVerbs\": {  /  \"mode\": \"replace\" or \"append\",  /  \"verbs\": ["
  fi

  if ! diff -q <(tail -n 3 "$tmp/file.json") "$tmp/expected_tail" > /dev/null; then
    fail "[$short] last three lines must be exactly: ]  /  }  /  }"
  fi

  if ! jq -e '.spinnerVerbs.verbs | type == "array"' "$tmp/file.json" > /dev/null 2>&1; then
    fail "[$short] $FILE is not valid JSON or has no spinnerVerbs.verbs array"
    return
  fi

  while IFS= read -r verb; do
    fail "[$short] verb may only contain letters, digits, and hyphens: \"$verb\""
  done < <(jq -r '.spinnerVerbs.verbs[] | tostring | select(test("^[A-Za-z0-9-]+$") | not)' "$tmp/file.json")

  while IFS= read -r verb; do
    fail "[$short] verb must start with a capital letter: \"$verb\""
  done < <(jq -r '.spinnerVerbs.verbs[] | tostring | select(test("^[A-Z]") | not)' "$tmp/file.json")

  while IFS= read -r verb; do
    fail "[$short] verb must end in \"ing\": \"$verb\""
  done < <(jq -r '.spinnerVerbs.verbs[] | tostring | select(test("ing$") | not)' "$tmp/file.json")

  while IFS= read -r dupes; do
    fail "[$short] duplicate verb (case-insensitive): $dupes"
  done < <(jq -r '.spinnerVerbs.verbs | map(tostring) | group_by(ascii_downcase)[] | select(length > 1) | join(" / ")' "$tmp/file.json")

  while IFS= read -r order; do
    fail "[$short] verbs are out of alphabetical order: $order"
  done < <(jq -r '
    .spinnerVerbs.verbs | map(tostring) as $v
    | ($v | sort_by(ascii_downcase)) as $s
    | [range(0; $v | length) | select($v[.] != $s[.])] as $bad
    | if ($bad | length) == 0 then empty
      else "\($v[$bad[0]]) should be replaced by \($s[$bad[0]]) at that position" end' "$tmp/file.json")
}

# Commits to check: every commit in the range that touches the file.
# Falls back to HEAD for new branches, or when no commit in the range touches the file.
commits=()
if [ -n "$BASE_SHA" ] && [ "$BASE_SHA" != "$ZERO" ]; then
  while IFS= read -r c; do
    [ -n "$c" ] && commits+=("$c")
  done < <(git rev-list --reverse "$BASE_SHA..$HEAD_SHA" -- "$FILE")
fi
if [ "${#commits[@]}" -eq 0 ]; then
  commits=("$HEAD_SHA")
fi

for c in "${commits[@]}"; do
  check_commit "$c"
done

if [ "$errors" -gt 0 ]; then
  if [ -n "$REPORT_FILE" ]; then
    cp "$tmp/problems.txt" "$REPORT_FILE"
  fi
  echo "$errors problem(s) found in $FILE. See annotations above."
  exit 1
fi
echo "All ${#commits[@]} checked commit(s) pass."
