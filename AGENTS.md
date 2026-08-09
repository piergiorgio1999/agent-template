# AGENTS.md

## Source of truth

GitHub è la sola fonte autorevole dello stato del progetto.

Non creare file di stato locali.

Non aggiornare manualmente roadmap, task list o status.

## Prima di lavorare

Prima di qualsiasi modifica, leggi `SPEC-V1.md`.

Leggi nell'ordine:

1. Project Status Digest
2. Issue assegnata
3. PR collegata (se presente)
4. DECISIONS.md
5. File realmente coinvolti

Non effettuare scansioni massive del repository salvo richiesta esplicita.

## Decisioni

Le decisioni permanenti vivono esclusivamente in DECISIONS.md.

Le Issue devono referenziare le decisioni.

Mai duplicare la rationale.

## Scope

Una PR modifica un solo functional scope.

shared/core è consentito solo se dichiarato.

File non classificati:

FAIL.

## Stato progetto

Usa sempre Project Status Digest.

Mai ricostruire manualmente lo stato leggendo commit, branch o cronologia.

## Digest

Il digest è READ ONLY.

Non modificarlo.

Non salvarlo come stato permanente.

## Tool

Usare prima i controlli deterministici.

Ricorrere al modello LLM solo quando i controlli automatici non sono sufficienti.
