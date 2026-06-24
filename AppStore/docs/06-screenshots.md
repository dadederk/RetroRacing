# Screenshot Assets & Storyboard

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-06-24
**See also:** [ES/CA slide copy](../../Plans/aso/02-screenshot-localization-copy.md) · [PPO](09-product-page-optimization.md)


---

## Screenshot Assets

Screenshot Studio project:

- [Project root](../RetroRacing.screenshotstudio/)
- [iPhone source copy](../RetroRacing.screenshotstudio/iphone/data.plist)
- [iPad source copy](../RetroRacing.screenshotstudio/ipad/data.plist)
- [Mac source copy](../RetroRacing.screenshotstudio/mac/data.plist)
- [Apple Watch source copy](../RetroRacing.screenshotstudio/appleWatch/data.plist)
- [Project settings](../RetroRacing.screenshotstudio/project.plist)

Current source state on 2026-06-24:

- **Locales in project:** `en-US`, `en-GB`, `en-AU`, `en-CA`, `es-ES`, `es-MX`, `ca` (see `project.plist`).
- iPhone, iPad, and Mac source copy uses the **seven-slide storyboard** for all locales above.
- `en-GB` and `en-AU` use British spelling in overlay copy (`Customise Your Experience`). `en-CA` matches US spelling.
- **Shared base captures:** English variants reuse the same underlying device captures (`en-US_*` copied to `en-GB_*`, `en-AU_*`, `en-CA_*`). After the first `es-ES` export, `es-MX` reuses the same captures; only overlay copy differs (`carro` / `rebasar` on slide 1).
- Mac source plist now has seven slides with filled Spanish/Catalan copy; rendered Mac exports still need regeneration (slides 6–7 and all `es-ES` / `es-MX` / `ca` PNGs).
- iPhone has English-variant JPEG exports; `es-ES`, `es-MX`, and `ca` JPEGs must be re-exported from Screenshot Studio.
- iPad has locale manifests but no rendered exports yet.
- Apple Watch stays **sequence-first**: English locales keep the hook overlay on slide 1; `es-ES`, `es-MX`, and `ca` use empty overlay text.
- Re-sync copy and manifests after edits: `swift Scripts/SyncScreenshotStudioLocalizations.swift` (from repo root)
- ScreenshotStudio still has Apple TV and Apple Vision selected in project settings. Apple TV should be parked unless tvOS is actively shipping. Apple Vision needs a product decision because the public App Store listing shows compatibility.

### Current iPhone/iPad Sequence (source copy)

Source `data.plist` entries now match the recommended storyboard below for all English variants. Re-export screenshots from Screenshot Studio before uploading to App Store Connect.

| # | Title | English body | Notes |
|---:|---|---|---|
| 1 | `Race Through Endless Traffic` | `Navigate your car, dodge rivals, and rack up overtakes in this retro-inspired arcade racer.` | Hook |
| 2 | `Simple Controls. Pure Arcade Action` | `Move left. Move right. Don't crash. Master the basics in seconds, then chase your high score for hours.` | Controls |
| 3 | `Built For Accessibility` | `VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings.` | Differentiator |
| 4 | `One Wrong Move. Game Over` | `The speed climbs. One mistake ends your run. Restart fast and beat your best.` | Tension |
| 5 | `Climb the Leaderboards` | `Earn achievements, chase friends, and share your best runs with Game Center.` | Social proof |
| 6 | `Choose Your Retro Aesthetic` | `Switch from pocket-console green to LCD handheld style, and make every run feel properly retro.` | Themes |
| 7 | `Customize Your Experience` | `Tune controls, haptics, volume, visual style, and feedback so RetroRapid! fits your play style.` | Personalization (`Customise` on en-GB/en-AU) |

### Recommended Screenshot Storyboard

Use this as the next source-copy pass for iPhone, iPad, and Mac. Localize all slides before export.

| # | Title | Body | Purpose |
|---:|---|---|---|
| 1 | `Race Through Endless Traffic` | `Navigate your car, dodge rivals, and rack up overtakes in this retro-inspired arcade racer.` | Hook: what the game is. |
| 2 | `Simple Controls. Pure Arcade Action` | `Move left. Move right. Don't crash. Master the basics in seconds, then chase your high score for hours.` | Clarity: how it plays. |
| 3 | `Built For Accessibility` | `VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings.` | Differentiator: inclusive play without leading only with accessibility. |
| 4 | `One Wrong Move. Game Over` | `The speed climbs. One mistake ends your run. Restart fast and beat your best.` | Tension: why it is replayable. |
| 5 | `Climb the Leaderboards` | `Earn achievements, chase friends, and share your best runs with Game Center.` | Retention: social/replay proof. |
| 6 | `Choose Your Retro Aesthetic` | `Switch from pocket-console green to LCD handheld style, and make every run feel properly retro.` | Monetization/theme support. |
| 7 | `Customize Your Experience` | `Tune controls, haptics, volume, visual style, and feedback so RetroRapid! fits your play style.` | Personalization and trust. |

### Screenshot Title ASO Variants (First Three Slides)

Keep the warm body copy above. Industry ASO tools report screenshot-text indexing, but Apple does not publicly guarantee OCR ranking weight. Treat these as conversion-first PPO variants with possible search benefit, not as confirmed keyword fields.

If the first PPO test needs more direct titles, test these against the default titles without changing the overall story order:

| # | Default title | ASO title candidate | Notes |
|---:|---|---|---|
| 1 | `Race Through Endless Traffic` | `Endless Traffic Dodge Game` | More direct mechanic/category wording. |
| 2 | `Simple Controls. Pure Arcade Action` | `3-Lane Arcade Controls` | Reinforces the lane mechanic without repeating the approved visible metadata. |
| 3 | `Built For Accessibility` | `VoiceOver and Haptic Racing` | Accessibility differentiator with searchable terms; keep on slide 3, not slide 1. |

Watch screenshots:

- Keep them sequence-first unless there is a clean, legible watch overlay style.
- Recommended order: gameplay, Digital Crown/control moment, speed/tension, accessibility/help, result/high score.
- If overlay text is used, keep it extremely short and localized.

Mac screenshots:

- Mac now uses the same seven-slide story as iPhone/iPad.
- Spanish and Catalan overlay copy is filled in source; re-export all Mac locales from Screenshot Studio.
- Show keyboard/controller controls somewhere in the Mac set because Mac users will look for input clarity.

Apple Vision:

- The public App Store listing currently exposes a visionOS app, but the shipping target is a "Coming Soon" placeholder.
- Do not mention Apple Vision in description, promotional text, or screenshots until gameplay is functional.
- Decide separately whether to remove the visionOS version from sale or complete the experience. This is a product/distribution issue, not an ASO wording problem.

Apple TV:

- Do not export or upload Apple TV screenshots until tvOS is publicly supported.
- Keep tvOS ASO work in a separate launch plan so it does not dilute the current App Store promise.
