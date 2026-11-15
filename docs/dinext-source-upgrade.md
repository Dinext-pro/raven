# Dinext source upgrade

Selected upstream release: [v3.2.0](https://github.com/frappe/raven/releases/tag/v3.2.0).
Immutable upstream commit: `5a5e4c48e477831d82943ba241e20cc9fb6ce578`.
Dinext integration line: `dinext/main/v3`.

## Preserved company changes

The v3 line uses the upstream translation loader and retains Russian date formatting, translated document type labels, and the Russian catalog. The Dinext Desk overlay still needs the Frappe 15 widget. The fork retains its bundle, styles, settings flag and compatible message stream with the current channel read-permission check.

## Verification and activation

The Dinext acceptance workflow builds the candidate, migrates a disposable Frappe and ERPNext 15 site from the preceding fork revision, and runs the compatibility and browser suites. It installs the Dinext overlay after the Raven migration and tests both applications together. It reports the tested revision in the run summary. Test fixtures use synthetic records and require an enabled development test site and the System Manager role.

Deployments use an independently verified release and manifest. Upstream publication workflows are archived under `.github/imported-workflows-disabled`.

## Verification record — 2026-10-18

On the isolated Frappe **15.119.0** site, all 196 web unit tests and 13 server permission tests passed. Frozen workspace dependencies, the TypeScript/Vite web build and the separate Desk asset build passed. The application Cypress scenario verifies the Russian home screen and document language.

Frappe 15 server tests use a compatible base and the standard User/Raven User fixtures; message tests initialize the real local search index. Channel-name assertions follow the release's existing lowercase/hyphenated naming contract.

A full Frappe Semgrep scan reported 25 findings in files that are byte-for-byte identical to upstream v3.0.0, plus scan timeouts/partial parsing of upstream files. The scan is not globally clean. These findings were recorded for follow-up rather than suppressed or represented as a passing full audit. All 26 Dinext-specific source/test/metadata files passed the same 50-rule configuration without findings or parsing errors.

The repeatable Cypress project lives in this application. Its synthetic-fixture endpoints check `allow_tests`, development/test context and the System Manager role on every call; fixture data uses only reserved test identities. Run it only on a disposable test site.
