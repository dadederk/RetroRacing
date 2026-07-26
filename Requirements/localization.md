# Localization Requirements

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** In-app String Catalog rules, supported languages, voice/transcreation.
- **Must not break:** No hardcoded UI strings; keep all required locales at 100% in `Localizable.xcstrings`; never translate `RetroRapid` / `RetroRapid!`.
- **Key files:** `RetroRacingShared/Localizable.xcstrings`, `GameLocalizedStrings`, `Config/RetroRacingUniversalInfo.plist`
- **Adding a language:** follow [`AppStore/docs/08-locale-expansion.md`](../AppStore/docs/08-locale-expansion.md) (full package checklist).

## Supported languages

| In-app | Notes |
|---|---|
| `en` | Development / source |
| `en-GB`, `en-AU` | British spelling where it differs |
| `en-CA` | US spelling (matches `en`) |
| `de`, `nl`, `it`, `fr` | Friendly `du` / `je` / `tu` |
| `es` | Spain Spanish |
| `ca` | Valencian Meridional |
| `ja`, `ko`, `pt-BR`, `zh-Hant` | APAC / LatAm |

## Source of truth

| Asset | Path |
|---|---|
| Shared catalog | `RetroRacing/RetroRacingShared/Localizable.xcstrings` |
| Listing metadata | `AppStore/metadata/retrorapid-v1.5.json` |
| EU transcreation reference | `Scripts/Resources/eu_localizations.json` |
| APAC/LatAm reference | `Scripts/Resources/asia_latam_localizations.json` |
| Bundle localizations | `RetroRacing/Config/RetroRacingUniversalInfo.plist` (`CFBundleLocalizations`, `CFBundleAllowMixedLocalizations = true`) |

## Voice

- Transcreate for meaning and energy; avoid literal/bureaucratic phrasing.
- Preserve arcade tone (pit-stop paywall, punchy game-over, warm engagement).
- Do not translate `RetroRapid` / `RetroRapid!` (`BrandMark.swift`, `AGENTS.md`).

### Product terms (keep aligned with IAP / Game Center)

| Locale | Unlimited Plays | Achievements |
|---|---|---|
| `de` | Unbegrenzte Spiele | Erfolge |
| `nl` | Onbeperkt spelen | prestaties |
| `it` | Partite illimitate | obiettivi |
| `fr` | Parties illimitées | succès |
| `es` | Partidas ilimitadas | logros |
| `ca` | Partides il·limitades | assoliments |
| `ja` | 無制限プレイ | 実績 |
| `ko` | 무제한 플레이 | 업적 |
| `pt-BR` | Partidas Ilimitadas | conquistas |
| `zh-Hant` | 無限暢玩 | 成就 |

## Implementation

- Use String Catalog + `String(localized:)` (not `NSLocalizedString`).
- Stable semantic keys; no hardcoded UI strings in Swift.
- `GameLocalizedStrings` for SpriteKit/SwiftUI locale resolution.
- Catalan: prefer Valencian Meridional when forms differ.

## Testing

- Locale resolution tests cover every supported in-app language above.
- Keep translation completeness at 100% for required locales.

## New keys

When adding a key, provide all supported locales (`en` + English variants + `de`/`nl`/`it`/`fr`/`es`/`ca`/`ja`/`ko`/`pt-BR`/`zh-Hant`). Then run shared/universal unit tests.

SharePlay keys must stay concise, avoid em dashes, and ship real translations (not English placeholders) — see existing `shareplay_*` / `menu_play_with_friends_*` keys in the catalog.

## References

- [Add-language checklist](../AppStore/docs/08-locale-expansion.md)
- [testing.md](testing.md) · [accessibility.md](accessibility.md)
