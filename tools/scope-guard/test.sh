#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCOPE_GUARD="$SCRIPT_DIR/scope-guard"

pass=0
fail=0

assert_exit() {
    local desc="$1" expected="$2"
    shift 2
    local actual=0
    "$@" >/tmp/scope-guard-test-out.$$ 2>&1 || actual=$?
    if [[ "$actual" -eq "$expected" ]]; then
        echo "ok - $desc"
        pass=$((pass + 1))
    else
        echo "FAIL - $desc (expected exit $expected, got $actual)"
        cat /tmp/scope-guard-test-out.$$
        fail=$((fail + 1))
    fi
    rm -f /tmp/scope-guard-test-out.$$
}

make_repo() {
    local dir
    dir="$(mktemp -d)"
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email "test@example.com"
    git -C "$dir" config user.name "test"
    cp "$SCRIPT_DIR/../../scope-map.json" "$dir/scope-map.json"
    mkdir -p "$dir/tools/lib" "$dir/tools/scope-guard"
    cp "$SCRIPT_DIR/../lib/common.sh" "$dir/tools/lib/common.sh"
    cp "$SCOPE_GUARD" "$dir/tools/scope-guard/scope-guard"
    printf '# Architectural Decisions\n\n## entry one\n\nfirst decision.\n' > "$dir/DECISIONS.md"
    git -C "$dir" add -A
    git -C "$dir" commit -q -m base
    git -C "$dir" checkout -q -b feature
    echo "$dir"
}

run_guard() {
    local dir="$1"
    (cd "$dir" && ./tools/scope-guard/scope-guard main)
}

# Case 1: single functional scope only -> pass
repo="$(make_repo)"
mkdir -p "$repo/tools/scope-guard"
echo "x" > "$repo/tools/scope-guard/thing"
git -C "$repo" add -A
git -C "$repo" commit -q -m "single scope"
assert_exit "single functional scope passes" 0 run_guard "$repo"
rm -rf "$repo"

# Case 2: two functional scopes (no DECISIONS.md) -> fail
repo="$(make_repo)"
mkdir -p "$repo/tools/scope-guard" "$repo/checks/python"
echo "x" > "$repo/tools/scope-guard/thing"
echo "y" > "$repo/checks/python/thing"
git -C "$repo" add -A
git -C "$repo" commit -q -m "two scopes"
assert_exit "two functional scopes fails" 1 run_guard "$repo"
rm -rf "$repo"

# Case 3: DECISIONS.md alone (no functional scope) -> pass, edits allowed
repo="$(make_repo)"
printf '# Architectural Decisions\n\n## entry one (edited)\n\nchanged.\n' > "$repo/DECISIONS.md"
git -C "$repo" add -A
git -C "$repo" commit -q -m "decisions only, edited"
assert_exit "DECISIONS.md-only edit passes (dedicated PR path)" 0 run_guard "$repo"
rm -rf "$repo"

# Case 4: DECISIONS.md excluded from scope count -> single functional scope + appended decision -> pass
repo="$(make_repo)"
mkdir -p "$repo/tools/scope-guard"
echo "x" > "$repo/tools/scope-guard/thing"
printf '# Architectural Decisions\n\n## entry one\n\nfirst decision.\n\n## entry two\n\nnew decision.\n' > "$repo/DECISIONS.md"
git -C "$repo" add -A
git -C "$repo" commit -q -m "single scope + appended decision"
assert_exit "single scope + DECISIONS.md append passes" 0 run_guard "$repo"
rm -rf "$repo"

# Case 5: single functional scope + DECISIONS.md edit of existing entry -> fail
repo="$(make_repo)"
mkdir -p "$repo/tools/scope-guard"
echo "x" > "$repo/tools/scope-guard/thing"
printf '# Architectural Decisions\n\n## entry one (edited)\n\nchanged.\n' > "$repo/DECISIONS.md"
git -C "$repo" add -A
git -C "$repo" commit -q -m "single scope + edited decision"
assert_exit "single scope + DECISIONS.md edit fails" 1 run_guard "$repo"
rm -rf "$repo"

# Case 6: single functional scope + DECISIONS.md deletion of existing entry -> fail
repo="$(make_repo)"
mkdir -p "$repo/tools/scope-guard"
echo "x" > "$repo/tools/scope-guard/thing"
printf '# Architectural Decisions\n' > "$repo/DECISIONS.md"
git -C "$repo" add -A
git -C "$repo" commit -q -m "single scope + truncated decisions"
assert_exit "single scope + DECISIONS.md deletion fails" 1 run_guard "$repo"
rm -rf "$repo"

echo
echo "scope-guard test.sh: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
