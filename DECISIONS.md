# Architectural Decisions

Le decisioni permanenti vivono qui.

Le Issue devono referenziare le decisioni.

Non duplicare la rationale nelle Issue.

## 2026-08-09 — Attivazione anticipata dei checker per linguaggio

I checker in `checks/*/check.sh` erano dichiarati "Dormant" /
"Implementation is intentionally deferred". Decisione: attivarli ora
invece di aspettare, cablando tool OSS standard per linguaggio
(shellcheck, go vet + gofmt, ruff, cargo clippy, tsc + eslint, swift
build) e rendendo reali i job `detect` (rilevamento manifest) e
`security` (gitleaks, actionlint, zizmor) in `.github/workflows/ci.yml`.

Ogni check resta un no-op (exit 0) se il manifest del linguaggio non
è presente, quindi è sicuro anche su repository generati che non
usano tutti i linguaggi.
