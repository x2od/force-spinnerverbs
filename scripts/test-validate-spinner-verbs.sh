#!/usr/bin/env bash
# Tests .github/scripts/validate-spinner-verbs.sh against a throwaway git repo.
# Each case makes real commits, runs the validator on them, and checks the exit code.
# Usage: bash scripts/test-validate-spinner-verbs.sh
set -uo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
VALIDATOR="$REPO_ROOT/.github/scripts/validate-spinner-verbs.sh"
ZERO="0000000000000000000000000000000000000000"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp" || exit 1
git init -q -b main
git config user.name test
git config user.email test@example.com

passed=0
failed=0

commit_json() { # $1 = commit message; reads the new file content from stdin
  cat > forceSpinning.json
  git add forceSpinning.json
  git commit -qm "$1"
}

# run NAME WANT_EXIT BASE_SHA [SUBSTRING]
run() {
  local name=$1 want=$2 base=$3 want_text=${4:-} out code
  out=$(BASE_SHA="$base" HEAD_SHA=HEAD bash "$VALIDATOR" 2>&1)
  code=$?
  if [ "$code" -ne "$want" ]; then
    failed=$((failed + 1))
    echo "FAIL $name: exit $code, wanted $want"
    echo "$out" | sed 's/^/     /'
  elif [ -n "$want_text" ] && ! grep -qF -- "$want_text" <<< "$out"; then
    failed=$((failed + 1))
    echo "FAIL $name: output did not contain \"$want_text\""
    echo "$out" | sed 's/^/     /'
  else
    passed=$((passed + 1))
    echo "ok   $name"
  fi
}

# Base history: an unrelated commit, then a good verb file.
echo "# test" > README.md && git add README.md && git commit -qm "readme"
ROOT=$(git rev-parse HEAD)

jq -n '{spinnerVerbs: {mode: "append", verbs: ["Apex-compiling", "Data-loader-exporting", "Sandboxing"]}}' \
  | commit_json "good base"
GOOD=$(git rev-parse HEAD)
BASE_FILE="$tmp/base.json"
git show "$GOOD:forceSpinning.json" > "$BASE_FILE"

# Adds a verb and keeps the list sorted, so only the rule under test can fail.
add_sorted() { # $1 = verb
  jq --arg v "$1" '.spinnerVerbs.verbs += [$v] | .spinnerVerbs.verbs |= sort_by(ascii_downcase)' "$BASE_FILE"
}

reset_good() { git reset -q --hard "$GOOD"; }

# --- Good cases ---------------------------------------------------------------
run "good file passes" 0 "$ROOT"

reset_good; add_sorted "Flow-Debugging" | commit_json "mixed case after first letter"
run "later letters may be upper case" 0 "$GOOD"

reset_good; jq '.spinnerVerbs.mode = "replace"' "$BASE_FILE" | commit_json "replace mode"
run "replace mode passes" 0 "$GOOD"

reset_good; jq '.spinnerVerbs.verbs = []' "$BASE_FILE" | commit_json "empty list"
run "empty verbs array fails the wrapper check (array must open on its own line)" 1 "$GOOD" "first four lines"

reset_good; git commit -q --allow-empty -m "unrelated"
run "commit that does not touch the file passes" 0 "$GOOD"

# --- Wrapper and JSON ---------------------------------------------------------
reset_good; jq '.spinnerVerbs.mode = "merge"' "$BASE_FILE" | commit_json "bad mode"
run "mode other than replace or append fails" 1 "$GOOD" "first four lines"

reset_good; sed 's/"verbs": \[/"verbs" : [/' "$BASE_FILE" | commit_json "header changed"
run "changed header line fails" 1 "$GOOD" "first four lines"

reset_good; { cat "$BASE_FILE"; echo; } | commit_json "extra trailing line"
run "extra trailing line fails" 1 "$GOOD" "last three lines"

reset_good; echo '{' | commit_json "invalid json"
run "invalid JSON fails" 1 "$GOOD" "not valid JSON"

reset_good; jq '.spinnerVerbs.verbs = "Sandboxing"' "$BASE_FILE" | commit_json "verbs not an array"
run "verbs that is not an array fails" 1 "$GOOD" "not valid JSON"

# --- Verb rules ---------------------------------------------------------------
reset_good; add_sorted "Sand boxing" | commit_json "space"
run "space in a verb fails" 1 "$GOOD" "letters, digits, and hyphens"

reset_good; add_sorted "Sand_boxing" | commit_json "underscore"
run "underscore in a verb fails" 1 "$GOOD" "letters, digits, and hyphens"

reset_good; add_sorted "zebra-racing" | commit_json "lowercase first letter"
run "lowercase first letter fails" 1 "$GOOD" "capital letter"

reset_good; add_sorted "Flow-debug" | commit_json "does not end in ing"
run "verb not ending in ing fails" 1 "$GOOD" 'end in "ing"'

reset_good; add_sorted "sandboxing" | commit_json "case-insensitive duplicate"
run "case-insensitive duplicate fails" 1 "$GOOD" "duplicate verb"

reset_good; jq '.spinnerVerbs.verbs = ["Zebra-zapping"] + .spinnerVerbs.verbs' "$BASE_FILE" | commit_json "out of order"
run "out-of-order verbs fail" 1 "$GOOD" "alphabetical order"

reset_good; jq '.spinnerVerbs.verbs += [123]' "$BASE_FILE" | commit_json "non-string verb"
run "non-string verb fails" 1 "$GOOD" "capital letter"

# --- Commit range -------------------------------------------------------------
reset_good
jq '.spinnerVerbs.verbs += ["zebra-racing"]' "$BASE_FILE" | commit_json "bad commit"
add_sorted "Flow-Debugging" | commit_json "fix commit"
run "earlier bad commit still fails after a fix" 1 "$GOOD" "capital letter"

reset_good; git rm -q forceSpinning.json && git commit -qm "delete file"
run "deleting the file fails" 1 "$GOOD" "is missing"

reset_good
run "new branch (no base) checks HEAD" 0 "$ZERO"

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
