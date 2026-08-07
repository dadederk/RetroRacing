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
| `fr-CA` | Canadian French — consistently formal `vous`, not a clone of `fr`; Canadian vocabulary where relevant |
| `es` | Spain Spanish |
| `es-MX` | Mexican Spanish — `carro`, `rebase`, and an independent in-app/capture locale |
| `ca` | Valencian Meridional |
| `ja`, `ko` | APAC |
| `pt-BR` | Brazilian Portuguese |
| `pt-PT` | European Portuguese — neutral third-person forms without explicit `você`/`vocês`; not a clone of `pt-BR` (`Definições`, `ecrã`, `ficheiro`, …) |
| `zh-Hant` | Traditional Chinese (Taiwan-leaning) |
| `zh-Hans` | Simplified Chinese — not a script-only conversion of `zh-Hant` |
| `tr`, `pl` | Turkish and Polish |

## Source of truth

| Asset | Path |
|---|---|
| Shared catalog | `RetroRacing/RetroRacingShared/Localizable.xcstrings` |
| Listing metadata | `AppStore/metadata/retrorapid-v1.6.json` |
| Review status and approved digests | `AppStore/localization/review-status.json` |
| Generated reviewer sheets | `AppStore/localization/README.md` and `AppStore/localization/reviews/*.csv` |
| Bundle localizations | `RetroRacing/Config/RetroRacingUniversalInfo.plist` (`CFBundleLocalizations`, `CFBundleAllowMixedLocalizations = true`) |

## Voice

- Transcreate for meaning and energy; avoid literal/bureaucratic phrasing.
- Preserve arcade tone (pit-stop paywall, punchy game-over, warm engagement).
- Do not translate `RetroRapid` / `RetroRapid!` (`BrandMark.swift`, `AGENTS.md`).
- Keep the style titles `Pocket`, `LCD`, `Cartridge`, `CRT`, `Disc`, and `Polygon` unchanged across locales; localize the surrounding description.
- Sibling locales (`pt-BR`/`pt-PT`, `zh-Hant`/`zh-Hans`, `fr`/`fr-CA`) must stay **locale-true** — vocabulary and register differ.
- French Canadian uses formal `vous` throughout; French for France remains friendly `tu`.
- European Portuguese uses neutral third-person forms without explicit Brazilian `você`/`vocês`.
- Catalan uses Valencian Meridional consistently: prefer `teua`/`seua`, `hui`, `este`/`esta`, `ací`, appropriate `-ix` forms, `rellotge`, and `avançament`.
- Screenshot headlines use locale-appropriate casing, not mechanically copied English title casing.

### Product terms (keep aligned with IAP / Game Center)

| Locale | Unlimited Plays | Achievements |
|---|---|---|
| `de` | Unbegrenzte Spiele | Erfolge |
| `nl` | Onbeperkt spelen | prestaties |
| `it` | Partite illimitate | obiettivi |
| `fr` / `fr-CA` | Parties illimitées | succès |
| `es` / `es-MX` | Partidas ilimitadas | logros |
| `ca` | Partides il·limitades | assoliments |
| `ja` | 無制限プレイ | 実績 |
| `ko` | 무제한 플레이 | 업적 |
| `pt-BR` | Partidas ilimitadas | conquistas |
| `pt-PT` | Partidas ilimitadas | conquistas |
| `zh-Hant` | 無限暢玩 | 成就 |
| `zh-Hans` | 无限畅玩 | 成就 |
| `tr` | Sınırsız oyun | başarımlar |
| `pl` | Nielimitowane gry | osiągnięcia |

## Implementation

- Use String Catalog + `String(localized:)` (not `NSLocalizedString`).
- Stable semantic keys; no hardcoded UI strings in Swift.
- `GameLocalizedStrings` for SpriteKit/SwiftUI locale resolution.
- Catalan: prefer Valencian Meridional when forms differ.

## Testing

- Locale resolution tests cover every supported in-app language above.
- Keep translation completeness at 100% for required locales.
- `./retrorapid localization audit` performs the structural check used by `./retrorapid check`.
- `./retrorapid localization reviews --all` regenerates deterministic UTF-8 reviewer CSVs and their digest index.
- `./retrorapid localization audit --require-approval` is the release-readiness gate. Every non-English locale requires a fluent reviewer, date, `APPROVED` status, matching content digest, and no `needs_review` String Catalog entries.
- Any source or translation change changes the digest and invalidates the recorded approval.

## New keys

When adding a key, provide all supported locales. Then run shared/universal unit tests.

visionOS volume preflight, 3D Ready, model failure, and Return to 2D states use semantic catalog keys and must remain fully localized. Native surface snapping has no custom search, confirmation, recovery, or timeout copy.

SharePlay keys must stay concise, avoid em dashes, and ship real translations (not English placeholders) — see existing `shareplay_*` / `menu_play_with_friends_*` keys in the catalog.

## References

- [Add-language checklist](../AppStore/docs/08-locale-expansion.md)
- [testing.md](testing.md) · [accessibility.md](accessibility.md)
