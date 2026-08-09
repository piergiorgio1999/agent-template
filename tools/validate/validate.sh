#!/usr/bin/env bash
set -Eeuo pipefail

echo "=============================="
echo "Template Validation"
echo "=============================="

required=(
git
gh
jq
shellcheck
actionlint
copier
)

missing=0

for tool in "${required[@]}"
do
    if ! command -v "$tool" >/dev/null 2>&1
    then
        echo "❌ Missing: $tool"
        missing=1
    else
        echo "✅ $tool"
    fi
done

echo

echo "Repository checks"

test -f copier.yml
test -f AGENTS.md
test -f README.md
test -f scope-map.json

echo "✅ Repository structure OK"

exit "$missing"
