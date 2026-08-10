# ACC-19

Status: NOT RUN

Purpose: Copier update and integration profiles

Expected Result: infrastruttura aggiornata e codice project-specific intatto;
`standalone` non genera `mcp/`, mentre `mcp` genera il server locale, il
manifest e il lockfile MCP.

Implementation:
Generate disposable projects for both `integration_mode` values, assert the
expected paths and saved answer, then run `copier update` after adding a
project-specific file.
