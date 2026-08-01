# Locale Expansion Waves

Part of [ASO & growth plans](README.md).

Last updated: 2026-07-26

> **Ops checklist (canonical):** [`AppStore/docs/08-locale-expansion.md`](../../AppStore/docs/08-locale-expansion.md) — add-language + screenshot refresh.

## Completed

| Date | Locales | Package |
|---|---|---|
| 2026-07-23 | `de-DE`, `nl-NL`, `it`, `fr-FR` | Strings, metadata, screenshots, TestFlight, ASC drafts |
| 2026-07-25 | `ja`, `ko`, `pt-BR`, `zh-Hant` | Same + IAP/Game Center catalogs |
| 2026-07-25 | `es-ES`, `es-MX`, `ca` IAP; `es-ES`, `ca` Game Center | Closed gap (listing/strings already existed) |
| 2026-07-26 | `pt-PT`, `zh-Hans`, `fr-CA` | Full package (locale-true; all three source capture) |

## Future candidates (provisional priority)

This is the working backlog for future localization waves. Treat the order as a market/effort hypothesis, not a shipping commitment; re-check App Store storefront traction, support load, screenshot cost, and translation quality before starting a wave.

| Rank | Locale | Notes |
|---:|---|---|
| 1 | `tr` — Turkish | Next highest-priority candidate after the current Europe/APAC/LatAm expansion. |
| 2 | `pl` — Polish | Strong EU follow-on candidate; likely lower engineering risk than RTL/locales with larger layout variance. |
| 3 | `ar` — Arabic | Large opportunity, but requires right-to-left UI, screenshot, metadata, and Game Center/IAP QA before release. |
| 4 | `th` — Thai | Good Southeast Asia expansion candidate; validate text fitting carefully because compact UI copy can expand unpredictably. |
| 5 | `vi` — Vietnamese | Southeast Asia follow-on candidate; consider alongside Indonesian for a regional wave. |
| 6 | `id` — Indonesian | Large audience candidate; likely best batched with Vietnamese once SEA storefront data supports it. |

Hindi (`hi`) remains a possible later candidate if India storefront traction justifies the added localization and support work, but it is no longer ahead of the six-language provisional backlog above.
