#!/usr/bin/env bash
set -Eeuo pipefail

status_emoji() {
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        success) printf '🟢' ;;
        skipped|neutral|not_applicable) printf '⚪' ;;
        *) printf '🔴' ;;
    esac
}

[[ "$(status_emoji success)" == "🟢" ]]
[[ "$(status_emoji failure)" == "🔴" ]]
[[ "$(status_emoji skipped)" == "⚪" ]]

grep -Fq 'if (( gate_count > 0 && gate_pending == 0 )); then' "$(dirname "$0")/pr-verify"
if grep -Fq 'pending_count == 0 && gate_count > 0' "$(dirname "$0")/pr-verify"; then
    echo "pr-verification must follow CI Gate, not unrelated pending checks" >&2
    exit 1
fi
