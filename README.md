# Agent Template V0.1

Template GitHub-native per repository gestite tramite Issues, PR e CI Gate.

## Creazione di una repository derivata

```sh
copier copy <percorso-del-template> <percorso-della-repo>
cd <percorso-della-repo>
gh repo create --private --source . --remote origin
git push -u origin main
./tools/bootstrap-github
```

Il template non usa Use this template come percorso canonico. Le fixture del
template restano sotto `template-only/` e non vengono copiate nelle repo derivate.

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

Impostare `template_owner` e `default_branch` durante `copier copy`. Prima della
prima PR, sostituire `@OWNER` in `.github/CODEOWNERS` con il proprietario reale.

