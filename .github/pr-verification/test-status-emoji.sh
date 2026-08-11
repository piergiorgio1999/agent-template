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
