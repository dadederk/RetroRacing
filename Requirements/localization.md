# Localization Requirements

## Overview

RetroRacing uses modern Apple localization with String Catalogs and locale-aware APIs.
All user-facing copy must be localizable and sourced from shared localization assets.

## Supported Languages

- English: `en` (development/source language)
- English (UK): `en-GB` — British spelling where it differs (`favourite`, `colour`, `centre`, `customise`)
- English (Australia): `en-AU` — same British spelling conventions as `en-GB` for in-app copy
- English (Canada): `en-CA` — US spelling conventions for in-app copy (matches `en` strings)
- Spanish (Spain): `es`
- Catalan: `ca` (translations written in Valencian Meridional style)

## Source of Truth

- Shared catalog: `RetroRacing/RetroRacingShared/Localizable.xcstrings`
- Project regions: `RetroRacing/RetroRacing.xcodeproj/project.pbxproj`
- App Info.plist overlay: `RetroRacing/Config/RetroRacingUniversalInfo.plist`

The shared catalog is the primary source because shared UI and game surfaces are localized from `RetroRacingShared`.

## Implementation Rules

- Use String Catalog entries for all user-visible text.
- Prefer `String(localized:)` APIs (not `NSLocalizedString`).
- Keep keys stable and semantic for reusable copy (`settings`, `play`, `game_over_*`).
- Do not introduce hardcoded UI strings in Swift files.

## Shared Localization Helper

`GameLocalizedStrings` is the shared bridge for SpriteKit/SwiftUI and testable locale resolution.

- Default lookup: current locale
- Keep API minimal for maintainability; avoid custom locale-resolution code paths.

## App Bundle Integration

- The universal app target uses `Config/RetroRacingUniversalInfo.plist` as an overlay while keeping generated Info.plist enabled.
- Keep `CFBundleAllowMixedLocalizations = true` so localized resources from embedded/shared bundles are resolved correctly.
- Keep `CFBundleLocalizations = [en, en-GB, en-AU, en-CA, es, ca]` aligned with project-supported regions.

## Valencian Variant Guidelines

- Valencian copy should use valencia-meridional conventions.
- Keep wording consistent across gameplay, settings, accessibility labels, and tutorial/help copy.
- If a term is ambiguous between generic Catalan and Valencian usage, prefer Valencian form.

## Testing Strategy

- Unit tests must validate locale resolution for:
  - Spanish (`es`)
  - Catalan (`ca`)
- Keep translation completeness at 100% for required locales in the shared catalog.

## Maintenance

- When adding a new key, provide translations in:
  - `en`
  - `en-GB` and `en-AU` (British spelling variants where applicable; otherwise copy `en`)
  - `en-CA` (copy `en` unless Canadian wording is required)
  - `es`
  - `ca` (with Valencian Meridional phrasing)
- Engagement/paywall UX keys for the current menu/settings flow include:
  - `menu_engagement_prompt`
  - `menu_rate_game`
  - `menu_support_game`
  - `settings_theme_unlock_footnote`
- SharePlay UX keys must keep visible copy concise and accessibility copy explicit:
  - `menu_play_with_friends_free_footer` — visible footer, currently `Friend races are free.`
  - `menu_play_with_friends_free_hint` — accessibility hint, currently `SharePlay matches don’t use daily plays.`
  - `shareplay_your_score_row %lld`, `shareplay_score_row %@ %lld`, `shareplay_opponent_score_fallback_label`, and `shareplay_score_accessibility %@ %lld %lld` — HUD/result/waiting-after-loss score labels without “overtakes” row copy; English fallback copy uses concise `You: <score>` and `Friend: <score>` rows, while display names are used when available.
  - `shareplay_waiting_for_opponent_title` — waiting-after-loss overlay title; user-facing values use the shared concise score-row keys above.
  - `game_over_your_best %lld` — SharePlay result secondary stat copy.
  - SharePlay user-facing values must avoid em dashes and must provide real `es`/`ca` translations rather than English placeholders.
- After localization changes:
  - run shared and universal unit tests
  - verify no missing translations in String Catalog entries

## References

- [testing.md](testing.md)
- [accessibility.md](accessibility.md)
