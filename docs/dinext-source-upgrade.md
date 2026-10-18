# Dinext source upgrade

Selected upstream release: [v3.0.0](https://github.com/frappe/raven/releases/tag/v3.0.0).
Immutable upstream commit: `a732e10f9c8b2ab3446038396e3eea763da617e7`.
Dinext integration line: `main/v3`.

## Preserved company changes

Use the existing main/v3 line and retain its Russian localization and document-link rendering changes. Keep main/v2 available unchanged. The existing dinext-raven overlay remains responsible for Desk widget integration.

## Verification and activation

Use the existing Dinext validation workflow and the tests/build commands declared by the application. Browser and migration checks must use an isolated Frappe 15 test site with synthetic data. Upstream publication workflows remain disabled.

This source update does not change a running site or deployment manifest. A runtime cutover requires verified backups, the exact accepted fork commit and matching release evidence. Keep the preceding source line available for rollback.
