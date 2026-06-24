# RetroRapid! App Store Docs

Last updated: 2026-06-24

Themed documentation for App Store copy, ASO, screenshots, rollout, and execution.

**Start here** for all listing work. Task routing from plans: `Plans/INDEX.md` → this hub. Campaign playbooks: `Plans/aso/README.md`.

Legacy redirect: [RETRORAPID_APP_STORE_REFERENCE.md](RETRORAPID_APP_STORE_REFERENCE.md). (Renamed from `AppStoreAssets/` on 2026-06-24.)

## Agent quick-start

| If you need to… | Read |
|---|---|
| Apply staged metadata to App Store Connect | [03-submission-quality-gate.md](docs/03-submission-quality-gate.md) + `scripts/apply_retrorapid_metadata.py` |
| Copy/paste **live** name, subtitle, keywords, description | [02-listing-snapshot.md](docs/02-listing-snapshot.md) |
| Copy/paste **staged** metadata (next pass) | [05-metadata-copy.md](docs/05-metadata-copy.md) |
| Understand ASO rationale, cross-localization, keyword rules | [04-metadata-strategy.md](docs/04-metadata-strategy.md) |
| Deep-dive Appfigures / Krankie keyword tables | [appendices/README.md](docs/appendices/README.md) (add dated snapshots when captured) |
| Update ScreenshotStudio captions or storyboard order | [06-screenshots.md](docs/06-screenshots.md) + [ES/CA slide tables](../Plans/aso/02-screenshot-localization-copy.md) |
| Write release notes | [07-release-notes-voice.md](docs/07-release-notes-voice.md) |
| Copy/paste **staged** What's New for next submit | [05-metadata-copy.md](docs/05-metadata-copy.md#whats-new-candidate) |
| Check character/byte limits or validation status | [01-limits-and-sources.md](docs/01-limits-and-sources.md) + [12-validation-results.md](docs/12-validation-results.md) |
| See what's live vs staged | [02-listing-snapshot.md](docs/02-listing-snapshot.md) + [03-submission-quality-gate.md](docs/03-submission-quality-gate.md) |
| Plan new locales | [08-locale-expansion.md](docs/08-locale-expansion.md) |
| Run PPO or post-launch measurement | [09-product-page-optimization.md](docs/09-product-page-optimization.md) + [10-aso-improvement-loop.md](docs/10-aso-improvement-loop.md) |
| Track execution checklists | [11-execution-90-day.md](docs/11-execution-90-day.md) |
| GAAD featuring / nomination copy | [Plans/aso/06-gaad-featuring.md](../Plans/aso/06-gaad-featuring.md) |
| Past featuring nominations & voice guide | [Plans/aso/09-featuring-nominations-submitted.md](../Plans/aso/09-featuring-nominations-submitted.md) |
| IAP pricing experiments | [Plans/aso/04-pricing-strategy.md](../Plans/aso/04-pricing-strategy.md) |

## Table of contents

### Reference (canonical, current)

| # | Theme | Doc |
|---:|---|---|
| 01 | Limits & Apple sources | [docs/01-limits-and-sources.md](docs/01-limits-and-sources.md) |
| 02 | Live listing snapshot & ASC archive | [docs/02-listing-snapshot.md](docs/02-listing-snapshot.md) |
| 03 | Submission gate & Helm rollout | [docs/03-submission-quality-gate.md](docs/03-submission-quality-gate.md) |
| 04 | ASO review, strategy, cross-localization | [docs/04-metadata-strategy.md](docs/04-metadata-strategy.md) |
| 05 | Staged metadata copy (all locales) | [docs/05-metadata-copy.md](docs/05-metadata-copy.md) |
| 06 | Screenshots & storyboard | [docs/06-screenshots.md](docs/06-screenshots.md) |
| 07 | Release-note voice & archive | [docs/07-release-notes-voice.md](docs/07-release-notes-voice.md) |
| 08 | Country & language expansion | [docs/08-locale-expansion.md](docs/08-locale-expansion.md) |
| 09 | Product Page Optimization (PPO) | [docs/09-product-page-optimization.md](docs/09-product-page-optimization.md) |
| 10 | Post-submit improvement loop | [docs/10-aso-improvement-loop.md](docs/10-aso-improvement-loop.md) |
| 11 | 90-day execution plan | [docs/11-execution-90-day.md](docs/11-execution-90-day.md) |
| 12 | Validation results | [docs/12-validation-results.md](docs/12-validation-results.md) |
| 13 | Open questions | [docs/13-open-questions.md](docs/13-open-questions.md) |

### Campaign & historical plans

| Theme | Doc |
|---|---|
| ASO growth plan hub | [Plans/aso/README.md](../Plans/aso/README.md) |
| Decisions & priority actions | [Plans/aso/01-decisions-and-priorities.md](../Plans/aso/01-decisions-and-priorities.md) |
| Screenshot ES/CA copy (all 7 slides) | [Plans/aso/02-screenshot-localization-copy.md](../Plans/aso/02-screenshot-localization-copy.md) |
| Metadata pack v1 (**superseded**) | [Plans/aso/03-metadata-v1-superseded.md](../Plans/aso/03-metadata-v1-superseded.md) |
| IAP pricing test | [Plans/aso/04-pricing-strategy.md](../Plans/aso/04-pricing-strategy.md) |
| 60-day checklist (**historical**) | [Plans/aso/05-operational-checklist-60-day.md](../Plans/aso/05-operational-checklist-60-day.md) |
| GAAD featuring nomination | [Plans/aso/06-gaad-featuring.md](../Plans/aso/06-gaad-featuring.md) |
| Submitted featuring nominations (2× Updated & Upgraded) | [Plans/aso/09-featuring-nominations-submitted.md](../Plans/aso/09-featuring-nominations-submitted.md) |

### Research appendix

Add dated Appfigures/Krankie snapshots under `docs/appendices/` when captured (e.g. `appfigures-snapshot-2026-06.md`). Keep strategy decisions in `04-metadata-strategy.md`; park raw export tables in appendices.

## Related repo docs

- [Localization requirements](../Requirements/localization.md)
- [Monetization](../Requirements/monetization.md)
- [Xarra App Store reference](../../Xarra/AppStore/README.md) (portfolio pattern)
- [GAAD nomination draft](../Docs/GAADYS_2026_RETRORAPID_NOMINATION_DRAFT.md) (draft — see [Docs/README.md](../Docs/README.md))

## Scripts & assets

- `scripts/apply_retrorapid_metadata.py` — push staged fields to ASC 1.5 drafts via Helm (`--keywords-only` for keyword-only sync)
- `scripts/split_app_store_docs.py` — regenerate themed files from monolith (if ever needed)
- `RetroRacing.screenshotstudio/` — Screenshot Studio project

## Canonical vs historical

| Source | Status |
|---|---|
| `docs/02-listing-snapshot.md` | **Live** metadata currently in App Store Connect (v1.4.2 as of 2026-06-24) |
| `docs/04-metadata-strategy.md` + `docs/05-metadata-copy.md` | **Staged** metadata candidate for v1.5 |
| `docs/07-release-notes-voice.md` | Voice guide + shipped What's New archive |
| `Plans/aso/03-metadata-v1-superseded.md` | Historical March 2026 pack — do not apply |
| `docs/11-execution-90-day.md` | **Current** execution checklist |
| `Plans/aso/05-operational-checklist-60-day.md` | Historical — superseded by 90-day plan |
| `docs/appendices/` | Dated keyword-research snapshots (add when Appfigures/Krankie baselines are captured) |
