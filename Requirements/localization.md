# Localization Requirements

## Overview

RetroRacing uses modern Apple localization with String Catalogs and locale-aware APIs.
All user-facing copy must be localizable and sourced from shared localization assets.

## Supported Languages

- English: `en` (development/source language)
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
- Keep `CFBundleLocalizations = [en, es, ca]` aligned with project-supported regions.

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
  - `es`
  - `ca` (with Valencian Meridional phrasing)
- Engagement/paywall UX keys for the current menu/settings flow include:
  - `menu_engagement_prompt`
  - `menu_rate_game`
  - `menu_support_game`
  - `settings_theme_unlock_footnote`
- After localization changes:
  - run shared and universal unit tests
  - verify no missing translations in String Catalog entries

## References

- [testing.md](testing.md)
- [accessibility.md](accessibility.md)
