# Adding a Language

Part of [App Store docs hub](../README.md).

Last updated: 2026-08-05

**Canonical ops checklist** for shipping a new language end-to-end. In-app string rules: [`Requirements/localization.md`](../../Requirements/localization.md). Capture internals: [`Requirements/screenshot_capture.md`](../../Requirements/screenshot_capture.md).

## Agent summary

> Load this before adding a locale or refreshing screenshots. Do not invent a partial pipeline.

- **Scope:** One package — app strings, listing metadata, IAP, Game Center, screenshots, TestFlight notes, ASC apply.
- **Must not break:** Capture mode is DEBUG-only; never let `screenshots sync` overwrite source-locale pixels with `en-US`; credentials live in Keychain (`RetroRapid ASC *`).
- **Easy to miss:** IAP + Game Center are separate from listing metadata; Watch needs `--install-only` after staging; English variants are **not** needed for IAP/Game Center.

---

## Current coverage

| Layer | Locales |
|---|---|
| **In-app** | `en`, `en-GB`, `en-AU`, `en-CA`, `de`, `nl`, `it`, `fr`, `fr-CA`, `es`, `ca`, `ja`, `ko`, `pt-BR`, `pt-PT`, `zh-Hant`, `zh-Hans`; `tr`/`pl` are 1.6 candidates pending native review |
| **Listing metadata** | 20 staged locales; no 1.6 ASC draft IDs yet |
| **IAP / Game Center** | Same as listing **except** no `en-GB`/`en-AU`/`en-CA` (use `en-US`). IAP also has `es-MX`. |
| **Screenshot capture (source)** | `en-US`, `de-DE`, `nl-NL`, `it`, `fr-FR`, `fr-CA`, `es-ES`, `ca`, `ja`, `ko`, `pt-BR`, `pt-PT`, `zh-Hant`, `zh-Hans`, plus planned `tr`/`pl` |
| **Screenshot source (capture pixels)** | 17 locales, including independent `es-MX` |
| **Screenshot derived (copy pixels)** | `en-GB`/`en-AU`/`en-CA` ← `en-US` |

**Next candidates after the 1.6 Turkish/Polish review gate:** `ar` (Arabic) as a dedicated RTL wave, then `th` (Thai), `vi` (Vietnamese), and `id` (Indonesian). See [`Plans/aso/08-locale-expansion-waves.md`](../../Plans/aso/08-locale-expansion-waves.md). Hindi (`hi`) remains a later candidate only if India storefront data justifies the work.

---

## Easy to miss

1. **One package.** Shipping only String Catalog + listing metadata leaves paywall and Game Center in English on ASC.
2. **Locale code split.** In-app often uses `de` / `fr` / `es`; ASC / Studio use `de-DE` / `fr-FR` / `es-ES`. Map carefully (table below).
3. **Credentials.** `./retrorapid asc iap --asc-api` and `./retrorapid asc game-center` read Keychain services `RetroRapid ASC Key ID`, `Issuer ID`, `Private Key` (env vars still override).
4. **IAP Helm upload is flaky from agent shells.** Prefer `--asc-api`.
5. **Game Center has no Helm path.** Always ASC API via `./retrorapid asc game-center`.
6. **English variants:** needed for listing ASO + screenshot overlays; **not** for IAP/Game Center (identical copy; ASC falls back to `en-US`).
7. **Screenshots:** `sync` ≠ install. Capture writes staging; install copies into Studio; `sync` only updates manifests/overlays/derived copies. After a partial capture: `--install-only`.
8. **Watch is easy to skip.** Run watch capture (or `--install-only`) explicitly — iPhone install does not update Watch.
9. **Slide index shifts.** Inserting a slide (e.g. SharePlay) invalidates later indices for locales not re-captured — re-take from the new slide onward for those locales.
10. **Achievement capture.** Capture mode uses local fallback strings (`NoOpAchievementMetadataService`), not live Game Center English metadata.
11. **Related-language keywords.** Avoid duplicate tokens across related pairs (e.g. `pt-BR` ↔ `es-MX`); prefer native forms (`recorde` not `record`).
12. **Manual ASC screenshot upload.** Capture → Studio → **export in Studio → upload in Connect** (not automated).
13. **Website URLs.** ASC marketing and support websites are localized fields too; reuse the English URLs until localized pages exist.

---

## Locale code map

| In-app / catalog | ASC / Studio / IAP / GC |
|---|---|
| `en` | `en-US` |
| `en-GB`, `en-AU`, `en-CA` | same (listing + screenshots only) |
| `de` | `de-DE` |
| `nl` | `nl-NL` |
| `it` | `it` |
| `fr`, `fr-CA` | `fr-FR`, `fr-CA` |
| `es`, `es-MX` | `es-ES`, `es-MX` |
| `ca` | `ca` |
| `ja`, `ko`, `pt-BR`, `pt-PT`, `zh-Hant`, `zh-Hans` | same |
| `tr`, `pl` | same |

---

## Checklist: add a new language

Work top to bottom. Tick every box before calling the locale done.

### 1. In-app strings

- [ ] Add locale to `RetroRacing/RetroRacingShared/Localizable.xcstrings` (100% keys; transcreate, don’t literal-translate; new/changed copy stays `needs_review`)
- [ ] Align product terms (Unlimited Plays, achievements wording) with IAP/GC copy you’ll upload
- [ ] Add to `CFBundleLocalizations` in `RetroRacing/Config/RetroRacingUniversalInfo.plist`
- [ ] Add project region in `RetroRacing.xcodeproj` if required
- [ ] Extend `ScreenshotCaptureLocaleCatalog.appStoreLocales` + `inAppLanguageIdentifier` mapping
- [ ] Add locale coverage tests (`GameLocalizedStringsLocaleTests` / shared tests)
- [ ] Update [`Requirements/localization.md`](../../Requirements/localization.md) supported-language list
- [ ] Add tone/register guidance and `NEEDS_REVIEW` state to `AppStore/localization/review-status.json`
- [ ] Generate the locale CSV with `./retrorapid localization reviews --locale <ASC-locale>`
- [ ] Record a fluent reviewer, date, and the exact approved digest before capture or release readiness

### 2. App Store listing metadata

- [ ] Add locale block to the canonical version catalog (currently `AppStore/metadata/retrorapid-v1.6.json`) with name, subtitle, keywords, promo, description, and what’s new
- [ ] Create ASC version localization if missing (`helm-asc version <id> localizations create --locale …`)
- [ ] Configure ASC marketing website + support website for the locale (reuse `en-US` URLs until localized pages exist)
- [ ] Record `localizationIds` under `platformDrafts` for **iOS and macOS**
- [ ] `./retrorapid metadata generate` then `./retrorapid metadata apply` (or `--keywords-only` when only keywords changed)
- [ ] Check related-language keyword overlaps in your ASO tool

### 3. IAP (Unlimited Plays)

- [ ] Add `AppStore/iap-localizations/6759012658/<ASC-locale>/metadata.csv` (`name` ≤30, `description` ≤45)
- [ ] Add locale to `Scripts/Sources/ApplyIAPLocalizations/main.swift` `defaultLocales`
- [ ] `./retrorapid asc iap --check`
- [ ] `./retrorapid asc iap --asc-api`
- [ ] Confirm with `helm-asc inAppPurchase 6759012658 localizations --agent`

### 4. Game Center (achievements + leaderboards)

- [ ] Add locale to `AppStore/game-center/achievements-eu-localizations.json` (all 22 achievements)
- [ ] Add locale to `AppStore/game-center/leaderboards-eu-localizations.json` (score suffixes; display names built at upload)
- [ ] Extend `GameCenterLeaderboardDisplayNameBuilder` / `DescriptionBuilder` for the locale
- [ ] `./retrorapid asc game-center --check`
- [ ] `./retrorapid asc game-center` (long: ~220 achievement + ~120 leaderboard rows at 10 locales; images copy from `en-US`)
- [ ] Spot-check one achievement + one leaderboard in ASC for the new locale

### 5. Screenshot Studio overlay copy

- [ ] Add locale to `ScreenshotStudioWorkflow.locales`
- [ ] Add slide titles/bodies in `ScreenshotStudioWorkflow` `slides` (iPhone storyboard; Mac/Watch derive)
- [ ] `./retrorapid screenshots sync` (manifests + overlays; does **not** create new pixels)

### 6. Capture & install screenshots

See **Refresh screenshots** below. For a brand-new locale, capture **all platforms** for that locale:

```bash
./retrorapid screenshots capture --all-platforms --locales <ASC-locale> --force
```

If staging already has good files but Studio is stale:

```bash
./retrorapid screenshots capture --platform <iphone|ipad|mac|watch> --install-only
```

### 7. TestFlight notes

- [ ] Add `AppStore/testflight/beta-notes/<ASC-locale>/whats-new.txt`
- [ ] Apply to builds via Helm (`build update --locale … --whats-new …`) when shipping a beta

### 8. Final validation

- [ ] `./retrorapid check`
- [ ] Spot-check Screenshot Studio: in-app UI language matches locale (not English HUD)
- [ ] Spot-check ASC: listing, IAP, Game Center for the new locale
- [ ] Export screenshots from Studio and upload to Connect when ready for review

---

## Checklist: refresh screenshots

Use when copy/fixtures/locales already exist and you only need new pixels.

### Before capture

- [ ] Confirm slide → fixture map still matches [`Requirements/screenshot_capture.md`](../../Requirements/screenshot_capture.md) (SharePlay insert shifts indices)
- [ ] Decide scope: `--locales`, `--slides`, `--platform` / `--all-platforms`, `--force`

### Capture

```bash
# One platform, selected locales/slides
./retrorapid screenshots capture --platform iphone --locales ja,ko --slides 4,5,6,7,8 --force

# All shipping platforms
./retrorapid screenshots capture --all-platforms --force
```

| Platform | Slides | Notes |
|---|---|---|
| iPhone / iPad | 0–9 | JPEG; iPad landscape |
| Mac | 0–8 | PNG; no SharePlay slide (indices shift after 3) |
| Watch | 0–4 | JPEG; sequence-only overlays; set simulator locale via CLI |

### After capture

- [ ] Pipeline installs into Studio automatically; if Studio still shows English for a locale that has distinct staging files → `--install-only` for that platform
- [ ] `./retrorapid screenshots sync --check`
- [ ] Spot-check **source** locales in Studio (not only `en-US`)
- [ ] Derived locales (`en-GB`/`en-AU`/`en-CA`) should match `en-US` after sync — do not re-capture them
- [ ] Capture `es-MX` independently and confirm Mexican Spanish in-app UI (never Spain Spanish pixels)
- [ ] Export from Screenshot Studio → upload to App Store Connect (manual)

### Partial re-take rule

If you only re-capture some slides for some locales, **Studio keeps old files for the rest**. After a storyboard insert, re-take from the inserted index through the end for every locale that still has pre-insert captures.

---

## Commands cheat sheet

```bash
# Docs / metadata
./retrorapid metadata generate
./retrorapid metadata apply
./retrorapid metadata apply --keywords-only

# IAP + Game Center (Keychain credentials)
./retrorapid asc iap --check && ./retrorapid asc iap --asc-api
./retrorapid asc game-center --check && ./retrorapid asc game-center

# Screenshots
./retrorapid screenshots capture --all-platforms --force
./retrorapid screenshots capture --platform watch --install-only
./retrorapid screenshots sync --check

# Full package gate
./retrorapid check
```

---

## Related

| Topic | Doc |
|---|---|
| In-app localization rules | [`Requirements/localization.md`](../../Requirements/localization.md) |
| Capture mode / fixtures | [`Requirements/screenshot_capture.md`](../../Requirements/screenshot_capture.md) |
| Storyboard & Studio project | [`06-screenshots.md`](06-screenshots.md) |
| Cross-localization / keywords | [`04-metadata-strategy.md`](04-metadata-strategy.md) |
| Game Center upload details | [`../game-center/README.md`](../game-center/README.md) |
| Script commands | [`../../Scripts/README.md`](../../Scripts/README.md) |
| Completed waves (history) | [`../../Plans/aso/08-locale-expansion-waves.md`](../../Plans/aso/08-locale-expansion-waves.md) |
