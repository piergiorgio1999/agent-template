#!/usr/bin/env bash
set -Eeuo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURES="$DIR/tests/fixtures"

bash -n "$DIR/project-status"
jq empty "$FIXTURES/issues.json" "$FIXTURES/prs.json"

json="$(PROJECT_STATUS_MOCK_DIR="$FIXTURES" PROJECT_STATUS_MOCK_REPOSITORY="fixture/repository" "$DIR/project-status" json)"

jq -e '
  .repository == "fixture/repository" and
  (.done | index("#1 Closed work")) and
  (.current | index("#2 In progress")) and
  (.blocked | index("#3 Blocked work")) and
  (.next[0] == "#4 Next P2") and
  (.attention | index("PR #11 Conflicting issue 5")) and
  (.progress.features[0].closed == 1) and
  (.progress.features[0].total == 2)
' <<<"$json" >/dev/null

text="$(PROJECT_STATUS_MOCK_DIR="$FIXTURES" "$DIR/project-status" md)"
bytes="$(printf '%s' "$text" | wc -c | tr -d ' ')"
lines="$(printf '%s\n' "$text" | wc -l | tr -d ' ')"
(( bytes <= 8192 ))
(( lines <= 100 ))

echo "project-status tests: PASS"
