# Agent Template V0.1

Template GitHub-native per repository gestite tramite Issues, PR e CI Gate.

## Creazione di una repository derivata

```sh
copier copy <percorso-del-template> <percorso-della-repo>
cd <percorso-della-repo>
gh repo create --private --source . --remote origin
git push -u origin main
gh api --method POST "repos/OWNER/REPOSITORY/rulesets" --input .github/ruleset.json
```

Il template non usa Use this template come percorso canonico. I contenuti di
`template-only/` sono esclusi dalle repo derivate.

## Source of truth

- istruzioni: `AGENTS.md`
- decisioni: `DECISIONS.md`
- scope: `scope-map.json`
- lavoro e decomposizione: GitHub Issues e sub-issues
- implementazione: PR
- verifica: Checks/Actions
- stato: `tools/project-status` (digest read-only)

Non creare `STATUS.md`, `ROADMAP.md`, `TASKS.md`, `PLAN.md` o
`PROJECT_STATE.json`.

## Configurazione minima

Impostare `template_owner` e `default_branch` durante `copier copy`. Il valore
di `template_owner` viene scritto in `.github/CODEOWNERS`; prima di applicare il
ruleset, sostituire `OWNER/REPOSITORY` nel comando con la repository reale.
