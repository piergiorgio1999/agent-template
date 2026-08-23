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
  (.current_prs[0].pr == "#10") and
  (.current_prs[0].diagnosis == "PASS: checks complete") and
  ([.current_prs[] | select(.pr == "#20") | .diagnosis] | .[0] == "WAIT: external check incomplete") and
  ([.current_prs[] | select(.pr == "#21") | .diagnosis] | .[0] == "WAIT: structured dependency is still open") and
  ([.current_prs[] | select(.pr == "#21") | .issue] | .[0] == "#21") and
  ([.current_prs[] | select(.pr == "#21") | .dependencies[0].number] | .[0] == 10) and
  ([.current_prs[] | select(.pr == "#21") | .dependencies[0].source] | .[0] == "Issue #21 blocked by Issue #2") and
  ([.current_prs[] | select(.pr == "#22") | .diagnosis] | .[0] == "WAIT: no checks visible") and
  ([.current_prs[] | select(.pr == "#22") | .issue] | .[0] == null) and
  ([.current_prs[] | .pr] | length == (unique | length)) and
  ((.current | index("#6 Blocked issue")) | not) and
  ((.current | index("#7 Needs attention")) | not) and
  (.blocked | index("#3 Blocked work")) and
  (.blocked | index("#6 Blocked issue")) and
  (.next[0] == "#4 Next P2") and
  ((.next | index("#7 Needs attention")) | not) and
  (.attention | index("#7 Needs attention")) and
  (.attention | index("PR #11 Conflicting issue 5")) and
  (.attention | index("PR #13 Attention issue 2")) and
  (.attention | index("PR #14 Action required")) and
  ((.attention | index("PR #12 Blocked issue 6")) | not) and
  (.progress.features[0].closed == 1) and
  (.progress.features[0].total == 2)
' <<<"$json" >/dev/null

diagnose_json="$(PROJECT_STATUS_MOCK_DIR="$FIXTURES" "$DIR/project-status" diagnose --all json)"
jq -e '
  (.ci_diagnostics | length) == 2 and
  .ci_diagnostics[0].pr == 11 and
  .ci_diagnostics[0].job == "security" and
  .ci_diagnostics[0].step == "Zizmor" and
  .ci_diagnostics[0].location == "src/workflow.yml:42:7" and
  .ci_diagnostics[1].location == null
' <<<"$diagnose_json" >/dev/null

live_json="$(PATH="$DIR/tests/fake-bin:$PATH" "$DIR/project-status" diagnose --all json)"
live_text="$(PATH="$DIR/tests/fake-bin:$PATH" "$DIR/project-status" diagnose --all md)"
jq -e '
  ([.current_prs[] | select(.pr == "#130") | .diagnosis][0] == "PASS: checks complete") and
  ([.current_prs[] | select(.pr == "#130") | .checks[]] == ["CI Gate 🟢 success"]) and
  ([.ci_diagnostics[] | select(.pr == 130)] | length == 0) and
  ([.ci_diagnostics[] | select(.pr == 131)] | length == 1) and
  ([.ci_diagnostics[] | select(.pr == 131)][0].error | contains("error[dangerous-triggers]")) and
  ([.ci_diagnostics[] | select(.pr == 131)][0].error | contains("pull_request_target")) and
  ([.ci_diagnostics[] | select(.pr == 131)][0].error | contains("Process completed with exit code") | not) and
  ([.ci_diagnostics[] | select(.pr == 131)][0].evidence | length > 1) and
  ([.ci_diagnostics[] | select(.pr == 131)][0].affected_paths == [".github/workflows/example.yml"]) and
  ([.ci_diagnostics[] | select(.pr == 131)][0].location == "./.github/workflows/example.yml:3:1") and
  ([.ci_diagnostics[] | select(.pr == 131)][0].escalation | startswith("INSUFFICIENT:")) and
  ([.current_prs[] | select(.pr == "#131")][0].dependencies[0].number == 130) and
  ([.current_prs[] | select(.pr == "#131")][0].dependencies[0].source == "Issue #31 blocked by Issue #30") and
  ([.current_prs[] | select(.pr == "#131")][0].related[0].target == 130) and
  ([.current_prs[] | select(.pr == "#131")][0].diagnosis == "WAIT: structured dependency is still open") and
  ([.current_prs[] | select(.pr == "#132")][0].issue == null) and
  ([.current_prs[] | select(.pr == "#132")][0].declared_closing_refs == [999]) and
  ([.current_prs[] | select(.pr == "#132")][0].recognized_closing_refs == []) and
  ([.current_prs[] | select(.pr == "#132")][0].related == []) and
  ([.ci_diagnostics[] | select(.pr == 132)] | length == 1) and
  ([.ci_diagnostics[] | select(.pr == 132)][0].error == "linking: exactly one closing issue reference is required") and
  ([.ci_diagnostics[] | select(.pr == 132)][0].escalation == "FIX: address the reported failure")
' <<<"$live_json" >/dev/null

text="$(PROJECT_STATUS_MOCK_DIR="$FIXTURES" "$DIR/project-status" md)"
diagnose_text="$(PROJECT_STATUS_MOCK_DIR="$FIXTURES" "$DIR/project-status" diagnose --all md)"
targeted_text="$(PROJECT_STATUS_MOCK_DIR="$FIXTURES" "$DIR/project-status" diagnose --pr 11 md)"
grep -Fq '## CI Diagnostics' <<<"$diagnose_text"
grep -Fq 'src/workflow.yml:42:7' <<<"$diagnose_text"
grep -Fq '#11 Conflicting issue 5' <<<"$targeted_text"
if grep -Fq '#10 Implements issue 2' <<<"$targeted_text"; then
  echo "targeted digest unexpectedly included an unselected PR" >&2
  exit 1
fi
grep -Fq 'DEPENDS-ON: PR #10 [OPEN] — Issue #21 blocked by Issue #2' <<<"$text"
grep -Fq '#22 Unlinked PR (no closing Issue)' <<<"$text"
grep -Fq 'RELATED: PR #130 [OPEN] — modifies failure path .github/workflows/example.yml' <<<"$live_text"
bytes="$(printf '%s' "$text" | wc -c | tr -d ' ')"
lines="$(printf '%s\n' "$text" | wc -l | tr -d ' ')"
(( bytes <= 8192 ))
(( lines <= 100 ))

long_fixture="$(mktemp -d)"
jq -n '[range(1;141) | {number: ., title: ("é issue " + tostring), state: "OPEN", labels: [], milestone: null, subIssues: [], blockedBy: [], blocking: []}]' > "$long_fixture/issues.json"
printf '%s\n' '[]' > "$long_fixture/prs.json"
long_text="$(PROJECT_STATUS_MOCK_DIR="$long_fixture" "$DIR/project-status" md)"
long_bytes="$(printf '%s' "$long_text" | wc -c | tr -d ' ')"
long_lines="$(printf '%s\n' "$long_text" | wc -l | tr -d ' ')"
(( long_bytes <= 8192 ))
(( long_lines <= 100 ))
grep -Fq '… truncated' <<<"$long_text"
grep -Fq '## Current PR' <<<"$text"
printf '%s' "$long_text" | iconv -f UTF-8 -t UTF-8 >/dev/null
rm -rf "$long_fixture"

# ---------------------------------------------------------------------------
# Repository map views (SPEC-V1.md section 13) — ACC-24, ACC-25.
#
# The map tool resolves its repository root from its own location, so the
# fixtures are exercised by materialising a disposable repository around a
# copy of the tool, the same way run-anti-rot.sh sandboxes agent-config-check.
# ---------------------------------------------------------------------------

bash -n "$DIR/map"

map_repo="$(mktemp -d)"
trap 'rm -rf "$map_repo"' EXIT

mkdir -p "$map_repo/tools/lib" "$map_repo/tools/project-status" "$map_repo/pkg" "$map_repo/deep"
cp "$DIR/../lib/common.sh" "$map_repo/tools/lib/common.sh"
cp "$DIR/map" "$map_repo/tools/project-status/map"
cp "$DIR/../../scope-map.json" "$map_repo/scope-map.json"

# All four supported package.json groups, plus labels carrying every character
# the contract requires to be escaped.
cat > "$map_repo/pkg/package.json" <<'JSON'
{
  "dependencies": { "alpha": "1.0.0", "a&b": "<1.0>", "quoted\"name": "2.0" },
  "devDependencies": { "beta": "2.0.0" },
  "optionalDependencies": { "gamma": "3.0.0" },
  "peerDependencies": { "delta": "4.0.0" }
}
JSON

# A supported manifest that declares nothing must still say so.
printf '%s\n' '{}' > "$map_repo/deep/package.json"

# Every recognized-but-unsupported manifest must be reported, never omitted.
printf '%s\n' '// swift' > "$map_repo/Package.swift"
printf '%s\n' '[project]' > "$map_repo/pyproject.toml"
printf '%s\n' 'requests' > "$map_repo/requirements.txt"
printf '%s\n' '[package]' > "$map_repo/Cargo.toml"
printf '%s\n' 'module x' > "$map_repo/go.mod"

git -C "$map_repo" init -q
git -C "$map_repo" add -A
map() { (cd "$map_repo" && ./tools/project-status/map "$@"); }

dep_outline="$(map dependencies outline)"

# Recognized but unsupported sources are explicit, never silently dropped.
for manifest in Package.swift pyproject.toml requirements.txt Cargo.toml go.mod; do
    grep -Fq "$manifest" <<<"$dep_outline"
done
(( $(grep -c 'details unavailable' <<<"$dep_outline") == 5 ))
grep -Fq 'no declared dependencies' <<<"$dep_outline"

# All four dependency groups of a package.json are exposed.
for group in dependencies devDependencies optionalDependencies peerDependencies; do
    grep -Eq "^ +$group\$" <<<"$dep_outline"
done

# Root literal and two-space indentation.
[[ "$(head -n1 <<<"$dep_outline")" == "repository" ]]
grep -Eq '^    pkg/package\.json$' <<<"$dep_outline"

# At least four levels below the root (ACC-24).
grep -Eq '^        alpha 1\.0\.0$' <<<"$dep_outline"

# Label escaping, in contract order, only in mermaid.
dep_mermaid="$(map dependencies mermaid)"
[[ "$(head -n1 <<<"$dep_mermaid")" == "flowchart TD" ]]
grep -Fq 'n0001["repository"]' <<<"$dep_mermaid"
grep -Fq 'a&amp;b &lt;1.0&gt;' <<<"$dep_mermaid"
grep -Fq 'quoted&quot;name 2.0' <<<"$dep_mermaid"
# & is escaped first: no entity is double-escaped.
if grep -Fq '&amp;amp;' <<<"$dep_mermaid"; then
    echo "map: & was double-escaped" >&2; exit 1
fi

# Both formats derive from the same ordered tree: equal node counts.
for map_type in dependencies ci; do
    outline_nodes="$(map "$map_type" outline | tail -n +2 | wc -l | tr -d ' ')"
    mermaid_nodes="$(map "$map_type" mermaid | grep -c '^  n[0-9]\{4\}\["')"
    (( outline_nodes == mermaid_nodes - 1 ))
done

# Byte-identical across runs, in every combination.
for map_type in dependencies ci; do
    for map_format in outline mermaid; do
        [[ "$(map "$map_type" "$map_format")" == "$(map "$map_type" "$map_format")" ]]
    done
done

# The CI view declares itself a contract view, not an extracted DAG.
ci_outline="$(map ci outline)"
grep -Fq 'contract view of SPEC section 9 (not an extracted workflow DAG)' <<<"$ci_outline"

# No timestamp, absolute path or environmental value leaks into the output.
for map_type in dependencies ci; do
    for map_format in outline mermaid; do
        rendered="$(map "$map_type" "$map_format")"
        if grep -Eq '/(Users|home|tmp|private)/' <<<"$rendered"; then
            echo "map: absolute path leaked into $map_type/$map_format" >&2; exit 1
        fi
        if grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}T' <<<"$rendered"; then
            echo "map: timestamp leaked into $map_type/$map_format" >&2; exit 1
        fi
    done
done

# Preview limits and the explicit omitted leaf (SPEC section 13 point 7).
{
    printf '{ "dependencies": {'
    for i in $(seq 1 400); do
        (( i > 1 )) && printf ','
        printf '"package-with-a-long-name-%03d": "1.0.0"' "$i"
    done
    printf '} }\n'
} > "$map_repo/pkg/package.json"
git -C "$map_repo" add -A

for map_format in outline mermaid; do
    preview="$(map dependencies "$map_format")"
    (( $(printf '%s\n' "$preview" | wc -c | tr -d ' ') <= 8192 ))
    (( $(printf '%s\n' "$preview" | wc -l | tr -d ' ') <= 100 ))
    grep -Eq 'omitted [0-9]+' <<<"$preview"
done

# The same node prefix is selected for both formats.
preview_outline_nodes="$(map dependencies outline | tail -n +2 | wc -l | tr -d ' ')"
preview_mermaid_nodes="$(map dependencies mermaid | grep -c '^  n[0-9]\{4\}\["')"
(( preview_outline_nodes == preview_mermaid_nodes - 1 ))

# --full keeps the same order without the preview limit and without the leaf.
full_outline="$(map dependencies outline --full)"
(( $(printf '%s\n' "$full_outline" | wc -l | tr -d ' ') > 100 ))
if grep -Eq 'omitted [0-9]+' <<<"$full_outline"; then
    echo "map: --full must not truncate" >&2; exit 1
fi
preview_outline="$(map dependencies outline)"
[[ "$(printf '%s\n' "$full_outline" | head -n 5)" == "$(printf '%s\n' "$preview_outline" | head -n 5)" ]]

# CLI grammar: invalid combinations are rejected.
for bad_args in "dependencies" "outline" "bogus outline" "dependencies bogus" \
                "dependencies outline mermaid" "dependencies outline --repo o/r" \
                "status outline"; do
    # shellcheck disable=SC2086
    if map $bad_args >/dev/null 2>&1; then
        echo "map: accepted invalid arguments: $bad_args" >&2
        exit 1
    fi
done

rm -rf "$map_repo"

echo "project-status tests: PASS"
