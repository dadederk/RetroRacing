# Turkish and Polish 1.6 Review Gate

Part of [App Store docs hub](../README.md).

Last updated: 2026-08-05

**Status:** `BLOCKED` — initial copy is complete, but captures and App Store Connect writes require fluent Turkish and Polish approval.

## Reviewer terminology

| Concept | Turkish (`tr`) | Polish (`pl`) |
|---|---|---|
| Unlimited Plays | Sınırsız Oyun | Nielimitowane Gry |
| Achievements | başarımlar | osiągnięcia |
| High score | yüksek skor / rekor | najlepszy wynik / rekord |
| Overtake | sollama | wyprzedzenie |
| Cruise / Fast / Rapid | Cruise / Hızlı / Rapid | Cruise / Szybki / Rapid |
| Style Gallery | Tarz Galerisi | Galeria Stylów |

Keep `RetroRapid!`, `SharePlay`, `Game Center`, `VoiceOver`, `Digital Crown`, `Pocket`, `LCD`, `8-Bit`, `16-Bit`, `Cruise`, and `Rapid` unchanged.

## Review package

| Layer | Source | Expected coverage |
|---|---|---:|
| In-app UI | `RetroRacing/RetroRacingShared/Localizable.xcstrings` | 363 keys per locale; state remains `needs_review` until approval |
| Listing | `AppStore/metadata/retrorapid-v1.6.json` | name, subtitle, keywords, promo, description, What's New |
| Unlimited Plays | `AppStore/iap-localizations/6759012658/<locale>/metadata.csv` | name ≤30, description ≤45 |
| Game Center | `AppStore/game-center/*.json` | 22 achievements and 12 leaderboards |
| Screenshots | `ScreenshotStudioWorkflow.slides` | 10 iPhone/iPad and 9 Mac overlays; Watch uses locale-true UI without overlays |
| TestFlight | `AppStore/testflight/beta-notes/<locale>/whats-new.txt` | release focus and tester prompts |

## Fluent review checklist

- [ ] Arcade tone is warm, concise, and natural rather than literal.
- [ ] Product terminology above is consistent across every layer.
- [ ] Turkish dotted/dotless `i` and casing are correct, including title-style screenshot captions.
- [ ] Polish cases, number agreement, and singular/plural forms read naturally.
- [ ] Placeholders (`%@`, `%lld`, and positional variants) are preserved and ordered correctly.
- [ ] VoiceOver strings describe controls and outcomes clearly when heard without the screen.
- [ ] Store name/subtitle/keywords are natural and relevant, not keyword stuffing.
- [ ] IAP and Game Center limits pass without abbreviations that harm meaning.
- [ ] All requested corrections have been applied consistently to in-app, store, IAP, Game Center, screenshots, and TestFlight copy.
- [ ] Reviewer name/date and approval are recorded below.

## Approval record

| Locale | Reviewer | Date | Status | Notes |
|---|---|---|---|---|
| `tr` | — | — | `PENDING` | Do not capture as final or apply remotely. |
| `pl` | — | — | `PENDING` | Do not capture as final or apply remotely. |

After approval, change all corresponding String Catalog states from `needs_review` to `translated`, run the complete validation gate, capture both locales on every shipping platform, and only then populate 1.6 App Store Connect IDs.
