# Changelog

## Unreleased

- Riassunto CI sulla PR (`pr-ci-report.yml`): un solo commento, sempre
  aggiornato, con tabella dei gate, step fallito con estratto di log e file
  toccati per cartella.
- Auto-merge in opt-in (`auto-merge-when-green.yml`): squash merge via API REST
  solo sulle PR con etichetta `automerge` e tutti i gate verdi.
- Deploy Cloudflare Pages parametrico: domande copier `is_website`, `site_dir`
  e `cloudflare_project`; `config/template/pages.json` e i due workflow Pages
  esistono solo nei progetti che pubblicano un sito.
- Initial template
