#!/usr/bin/env bash
set -Eeuo pipefail

echo "Acceptance Suite"

count=$(find ../cases -name 'ACC-*.md' | wc -l | tr -d ' ')

echo "Registered cases: $count"

echo
echo "Implementation pending."

exit 0
