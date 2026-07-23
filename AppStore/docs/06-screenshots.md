# Screenshot Assets & Storyboard

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-07-23

**Status:** source copy is `READY` (bodies tightened to ≤ ~10 words on 2026-07-17). For the current submission pass, iPhone/iPad/Mac reuse `en-US` base captures for every locale; iPhone is synced, Mac is synced for the five base captures currently present, and iPad still needs base captures. ASC uploads remain `PLANNED`.

**See also:** [ES/CA slide copy](../../Plans/aso/02-screenshot-localization-copy.md) · [PPO](09-product-page-optimization.md)


---

## Screenshot Assets

Screenshot Studio project:

- [Project root](../RetroRapid.screenshotstudio/)
- [iPhone source copy](../RetroRapid.screenshotstudio/iphone/data.plist)
- [iPad source copy](../RetroRapid.screenshotstudio/ipad/data.plist)
- [Mac source copy](../RetroRapid.screenshotstudio/mac/data.plist)
- [Apple Watch source copy](../RetroRapid.screenshotstudio/appleWatch/data.plist)
- [Project settings](../RetroRapid.screenshotstudio/project.plist)

Current source state on 2026-07-23:

- **Locales in project:** `en-US`, `en-GB`, `en-AU`, `en-CA`, `es-ES`, `es-MX`, `ca` (see `project.plist`).
- iPhone, iPad, and Mac source copy uses the **seven-slide storyboard** for all locales above.
- `en-GB` and `en-AU` use British spelling in overlay copy (`Customise Your Experience`). `en-CA` matches US spelling.
- **Shared base captures:** For this submission pass, iPhone, iPad, and Mac reuse the same underlying `en-US_*` device captures for every locale. Localized overlay copy still differs by locale in `data.plist`; the sync script fans out each available base capture to `en-GB`, `en-AU`, `en-CA`, `es-ES`, `es-MX`, and `ca`.
- iPhone has all seven `en-US` JPEG source captures synced to every locale; slide 5 uses the Game Center friend-marker capture.
- iPad has locale manifests but no rendered base captures yet. Add `en-US_0.jpeg` through `en-US_6.jpeg`, then rerun the sync script to reuse them for every locale.
- Mac source plist has seven slides with filled Spanish/Catalan copy. The existing five `en-US` PNG source captures are synced to every locale; add `en-US_5.png` and `en-US_6.png`, then rerun the sync script.
- iPad and Mac slide 5 copy is ready, but the source captures should be visually checked after export to ensure the screenshot actually shows the friend-marker moment.
- Apple Watch stays **sequence-first** and should not be replaced for this Game Center refresh unless a dedicated watch screenshot pass is done. Current watch images are base `en-US` sequence captures with empty overlay text.
- Re-sync copy and manifests after edits: `swift run --package-path Scripts sync-screenshot-studio-localizations`
- Verify copy, manifests, and shared locale images without writing: `swift run --package-path Scripts sync-screenshot-studio-localizations --check`
- Screenshot Studio `selectedPlatforms` should match shipping platforms only (iPhone, iPad, Mac, Apple Watch). Park Apple TV and Apple Vision until those products ship publicly.

### Approved Screenshot Storyboard (source copy)

Canonical source: `Scripts/Sources/RetroRacingAutomationCore/ScreenshotStudioWorkflow.swift`. Regenerate `data.plist` after edits with `swift run --package-path Scripts sync-screenshot-studio-localizations`; verify without writing via `--check`. This is the approved story for iPhone, iPad, and Mac — keep all localized exports aligned with this order.

Bodies target **≤ ~10 words** in English — one concrete beat per slide, not a second paragraph. Translated bodies may run a word or two longer, which is expected for Romance-language expansion.

| # | Title | English body (≤ ~10 words) | Purpose |
|---:|---|---|---|
| 1 | `Race Through Endless Traffic` | `Dodge traffic and chase overtakes in a retro arcade racer.` | Hook: what the game is. |
| 2 | `Simple Controls. Pure Arcade Action` | `Move left. Move right. Don't crash. That's the whole game.` | Clarity: how it plays. |
| 3 | `Built For Accessibility` | `VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings.` | Differentiator: inclusive play without leading only with accessibility. |
| 4 | `One Wrong Move. Game Over` | `One mistake ends your run. Restart fast, beat your best.` | Tension: why it is replayable. |
| 5 | `Chase Friends On The Road` | `Game Center markers show the rival score you're chasing.` | Retention: concrete friend-racing proof. |
| 6 | `Choose Your Retro Aesthetic` | `Switch between pocket-console green and LCD handheld styles anytime.` | Monetization/theme support. |
| 7 | `Customize Your Experience` | `Tune controls, haptics, volume, and visuals to fit your style.` | Personalization and trust. (`Customise` on en-GB/en-AU) |

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
- Spanish and Catalan overlay copy is filled in source. For now, reuse the `en-US` base captures for every Mac locale; add missing base captures before final export.
- Show keyboard/controller controls somewhere in the Mac set because Mac users will look for input clarity.

Apple Vision:

- The public App Store listing currently exposes a visionOS app, but the shipping target is a "Coming Soon" placeholder.
- Do not mention Apple Vision in description, promotional text, or screenshots until gameplay is functional.
- Decide separately whether to remove the visionOS version from sale or complete the experience. This is a product/distribution issue, not an ASO wording problem.

Apple TV:

- Do not export or upload Apple TV screenshots until tvOS is publicly supported.
- Keep tvOS ASO work in a separate launch plan so it does not dilute the current App Store promise.
