# Dinext source upgrade

Selected upstream release: [v3.0.0](https://github.com/frappe/raven/releases/tag/v3.0.0).
Immutable upstream commit: `a732e10f9c8b2ab3446038396e3eea763da617e7`.
Dinext integration line: `main/v3`.

## Preserved company changes

Use the existing main/v3 line and retain its Russian localization and document-link rendering changes. Keep main/v2 available unchanged. The existing dinext-raven overlay remains responsible for Desk widget integration.

## Verification and activation

Use the existing Dinext validation workflow and the tests/build commands declared by the application. Browser and migration checks must use an isolated Frappe 15 test site with synthetic data. Upstream publication workflows remain disabled.

This source update does not change a running site or deployment manifest. A runtime cutover requires verified backups, the exact accepted fork commit and matching release evidence. Keep the preceding source line available for rollback.

## Verification record — 2026-10-18

On the isolated Frappe **15.119.0** site, all 196 web unit tests and 13 server permission tests passed. Frozen workspace dependencies, the TypeScript/Vite web build and the separate Desk asset build passed. The application Cypress scenario verifies the Russian home screen and document language.

Frappe 15 server tests use a compatible base and the standard User/Raven User fixtures; message tests initialize the real local search index. Channel-name assertions follow the release's existing lowercase/hyphenated naming contract.

A full Frappe Semgrep scan reported 25 findings in files that are byte-for-byte identical to upstream v3.0.0, plus scan timeouts/partial parsing of upstream files. The scan is not globally clean. These findings were recorded for follow-up rather than suppressed or represented as a passing full audit. All 26 Dinext-specific source/test/metadata files passed the same 50-rule configuration without findings or parsing errors.

The repeatable Cypress project lives in this application. Its synthetic-fixture endpoints check `allow_tests`, development/test context and the System Manager role on every call; fixture data uses only reserved test identities. Run it only on a disposable test site.
