# RetroRapid! App Store Docs

Last updated: 2026-06-30

Themed documentation for App Store copy, ASO, screenshots, rollout, and execution.

**Start here** for all listing work. Task routing from plans: `Plans/INDEX.md` → this hub. Campaign playbooks: `Plans/aso/README.md`.

Legacy redirect: [RETRORAPID_APP_STORE_REFERENCE.md](RETRORAPID_APP_STORE_REFERENCE.md). (Renamed from `AppStoreAssets/` on 2026-06-24.)

## Agent quick-start

| If you need to… | Read |
|---|---|
| Edit the canonical v1.5 metadata | [`metadata/retrorapid-v1.5.json`](metadata/retrorapid-v1.5.json), then run `swift run --package-path Scripts generate-metadata-docs` |
| Apply staged metadata to App Store Connect | [03-submission-quality-gate.md](docs/03-submission-quality-gate.md) + [Scripts/README.md](../Scripts/README.md) |
| Review **live** public facts, name, subtitle, and keywords | [02-listing-snapshot.md](docs/02-listing-snapshot.md) |
| Copy/paste generated **staged** metadata | [05-metadata-copy.md](docs/05-metadata-copy.md) |
| Understand ASO rationale, cross-localization, keyword rules | [04-metadata-strategy.md](docs/04-metadata-strategy.md) |
| Deep-dive Appfigures / Krankie keyword tables | [appendices/README.md](docs/appendices/README.md) (add dated snapshots when captured) |
| Update ScreenshotStudio captions or storyboard order | [06-screenshots.md](docs/06-screenshots.md) + [ES/CA slide tables](../Plans/aso/02-screenshot-localization-copy.md) |
| Write release notes | [07-release-notes-voice.md](docs/07-release-notes-voice.md) |
| Copy/paste **staged** What's New for next submit | [05-metadata-copy.md](docs/05-metadata-copy.md#whats-new-candidate) |
| Check character/byte limits or validation status | [01-limits-and-sources.md](docs/01-limits-and-sources.md) + [12-validation-results.md](docs/12-validation-results.md) — regenerate with `swift run --package-path Scripts generate-metadata-docs --check` |
| See what's live vs staged | [02-listing-snapshot.md](docs/02-listing-snapshot.md) + [03-submission-quality-gate.md](docs/03-submission-quality-gate.md) |
| Plan new locales | [08-locale-expansion.md](docs/08-locale-expansion.md) |
| Run PPO or post-launch measurement | [09-product-page-optimization.md](docs/09-product-page-optimization.md) + [10-aso-improvement-loop.md](docs/10-aso-improvement-loop.md) |
| Track execution checklists | [11-execution-90-day.md](docs/11-execution-90-day.md) |
| GAAD featuring / nomination copy | [Plans/aso/06-gaad-featuring.md](../Plans/aso/06-gaad-featuring.md) |
| Past featuring nominations & voice guide | [Plans/aso/09-featuring-nominations-submitted.md](../Plans/aso/09-featuring-nominations-submitted.md) |
| IAP pricing experiments | [Plans/aso/04-pricing-strategy.md](../Plans/aso/04-pricing-strategy.md) |
| Upload a TestFlight build with Helm CLI | [14-testflight-helm-upload.md](docs/14-testflight-helm-upload.md) |

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
| 14 | TestFlight uploads with Helm CLI | [docs/14-testflight-helm-upload.md](docs/14-testflight-helm-upload.md) |

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

## Brand naming

| Context | Treatment |
|---|---|
| Installed app display name | `RetroRapid!` |
| App Store listing name | `RetroRapid: …` (no `!`) |
| Bundle IDs, targets, modules, repo paths | `RetroRacing` / `RetroRapid` (technical, no `!`) |

See [`../AGENTS.md`](../AGENTS.md) Brand Mark section and `RetroRacingShared/Utilities/BrandMark.swift`.

## Related repo docs

- [Localization requirements](../Requirements/localization.md)
- [Monetization](../Requirements/monetization.md)
- [Xarra App Store reference](../../Xarra/AppStore/README.md) (portfolio pattern)
- [GAAD nomination draft](../Docs/GAADYS_2026_RETRORAPID_NOMINATION_DRAFT.md) (draft — see [Docs/README.md](../Docs/README.md))

## Scripts & assets

- `metadata/retrorapid-v1.5.json` — canonical source for staged metadata, draft IDs, limits, and field status
- Repository automation lives at repo-root [`Scripts/`](../Scripts/) (Swift package for generating/validating docs and applying canonical metadata via Helm); see [Scripts/README.md](../Scripts/README.md)
- `RetroRapid.screenshotstudio/` — Screenshot Studio project (see [Legacy technical names](#legacy-technical-names))

## Active status vocabulary

| Status | Meaning |
|---|---|
| `LIVE` | Publicly available in the App Store |
| `DRAFT_APPLIED` | Written to an editable App Store Connect draft, not submitted |
| `READY` | Validated and approved for the next workflow step |
| `BLOCKED` | Cannot proceed until the named issue is resolved |
| `PLANNED` | Intended work that has not been applied |

Historical material uses **Historical** or **Superseded** and is never an active submission source.

## Canonical vs historical

| Source | Status |
|---|---|
| `docs/02-listing-snapshot.md` | `LIVE` metadata currently in App Store Connect (v1.4.2 snapshot from 2026-06-24) |
| `metadata/retrorapid-v1.5.json` | Canonical v1.5 candidate; version fields are `DRAFT_APPLIED`, name/subtitle are `BLOCKED` |
| `docs/05-metadata-copy.md` + `docs/12-validation-results.md` | Generated human-readable views of the canonical catalog |
| `docs/04-metadata-strategy.md` | Current rationale and keyword strategy |
| `docs/07-release-notes-voice.md` | Voice guide + shipped What's New archive |
| `Plans/aso/03-metadata-v1-superseded.md` | Historical March 2026 pack — do not apply |
| `docs/11-execution-90-day.md` | Current execution checklist |
| `Plans/aso/05-operational-checklist-60-day.md` | Historical — superseded by 90-day plan |
| `docs/appendices/` | Dated keyword-research snapshots (add when Appfigures/Krankie baselines are captured) |

## Legacy technical names

Some repository assets retain the **RetroRacing** technical prefix from early development:

| Asset | Location | Notes |
|---|---|---|
| Shipped app icon | `RetroRacingShared/Assets/RetroRapid.icon` | Canonical Xcode asset; wired in the project |
| Screenshot Studio | `AppStore/RetroRapid.screenshotstudio/` | Renamed from `RetroRacing.screenshotstudio` |
| Archived icon source | `Icon/_archive/RetroRacing.icon/` | Legacy design source; not referenced by Xcode |

Do not rename Xcode project references without a dedicated migration pass.

## Validation

RetroRapid's Scripts metadata pipeline (`generate-metadata-docs`, `check-documentation`) is canonical for staged catalog validation and generated docs. The generic Python script in `.agents/skills/app-store-aso/scripts/validate_metadata.py` remains available for ad-hoc ASO work only.

```bash
swift run --package-path Scripts generate-metadata-docs --check
swift run --package-path Scripts check-documentation
```
