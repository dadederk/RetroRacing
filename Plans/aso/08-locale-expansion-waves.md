# Locale Expansion Waves

Part of [ASO & growth plans](README.md).

Last updated: 2026-08-05

> **Ops checklist (canonical):** [`AppStore/docs/08-locale-expansion.md`](../../AppStore/docs/08-locale-expansion.md) — add-language + screenshot refresh.

## Completed

| Date | Locales | Package |
|---|---|---|
| 2026-07-23 | `de-DE`, `nl-NL`, `it`, `fr-FR` | Strings, metadata, screenshots, TestFlight, ASC drafts |
| 2026-07-25 | `ja`, `ko`, `pt-BR`, `zh-Hant` | Same + IAP/Game Center catalogs |
| 2026-07-25 | `es-ES`, `es-MX`, `ca` IAP; `es-ES`, `ca` Game Center | Closed gap (listing/strings already existed) |
| 2026-07-26 | `pt-PT`, `zh-Hans`, `fr-CA` | Full package (locale-true; all three source capture) |
| 2026-08-05 | `tr`, `pl`; promoted `es-MX` | Complete 1.6 package staged locally; `es-MX` now has 363 in-app strings, Game Center coverage, and independent source capture |
| 2026-08-05 | All 16 non-English locales | Editorial quality pass opened with digest-bound fluent approval; no locale is release-ready until its review manifest entry is approved |

## In preparation

| Release | Locales | Status |
|---|---|---|
| 1.6 | `tr`, `pl` | Local strings, metadata, IAP, Game Center, TestFlight, and screenshot copy prepared; fluent review, captures, 1.6 draft IDs, and ASC application pending. |

## Future candidates (provisional priority)

This is the working backlog for future localization waves. Treat the order as a market/effort hypothesis, not a shipping commitment; re-check App Store storefront traction, support load, screenshot cost, and translation quality before starting a wave.

| Rank | Locale | Notes |
|---:|---|---|
| 1 | `ar` — Arabic | Next dedicated wave; requires right-to-left UI, screenshot, metadata, and Game Center/IAP QA before release. |
| 2 | `th` — Thai | Good Southeast Asia expansion candidate; validate text fitting carefully because compact UI copy can expand unpredictably. |
| 3 | `vi` — Vietnamese | Southeast Asia follow-on candidate; consider alongside Indonesian for a regional wave. |
| 4 | `id` — Indonesian | Large audience candidate; likely best batched with Vietnamese once SEA storefront data supports it. |

Hindi (`hi`) remains a possible later candidate if India storefront traction justifies the added localization and support work, but it is no longer ahead of the six-language provisional backlog above.
