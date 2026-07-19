# Screenshot Localization Copy (All Slides)

Part of [ASO & growth plans](README.md). Index: [retrorapid_aso_growth_plan.md](../retrorapid_aso_growth_plan.md).

Last updated: 2026-07-17
**See also:** [Current storyboard](../../AppStore/docs/06-screenshots.md) · Canonical source: `Scripts/Sources/RetroRacingAutomationCore/ScreenshotStudioWorkflow.swift` · Sync command: `swift run --package-path Scripts sync-screenshot-studio-localizations`

---

## 4) Screenshot Messaging Plan

## 4.1 Positioning Rule

- Slide 1 should sell the game loop.
- Accessibility should appear early (slide 2/3), but not replace the gameplay hook.
- Game Center should appear as replayability support, not as headline proposition.
- Bodies target **≤ ~10 words** in English; one beat per slide, no repeated ground. Translated bodies may run a word or two longer.

## 4.2 iPhone Caption Sequence

Current iPhone/iPad/Mac source copy uses this **seven-slide** order. Locales: `en-US`, `en-GB`, `en-AU`, `en-CA`, `es-ES`, `es-MX`, `ca`. English variants share the same base captures; `es-MX` shares `es-ES` captures with Mexico-specific overlay copy on slide 1. Full per-locale text lives only in the canonical Swift source and generated `data.plist` files — not duplicated per-language below.

Translations use vocabulary consistent with `Localizable.xcstrings` and App Store metadata. CA follows **Valencian Meridional** dialect: `trànsit` for traffic, `teua`/`seua` for feminine possessives, `este`/`esta` for proximal demonstratives, Valencian verb forms (`gaudix`, `resistix`, `valga`).

| # | Title (EN) | Body (EN, ≤ ~10 words) |
|---|------------|-----------|
| 1 | `Race Through Endless Traffic` | `Dodge traffic and chase overtakes in a retro arcade racer.` |
| 2 | `Simple Controls. Pure Arcade Action` | `Move left. Move right. Don't crash. That's the whole game.` |
| 3 | `Built For Accessibility` | `VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings.` |
| 4 | `One Wrong Move. Game Over` | `One mistake ends your run. Restart fast, beat your best.` |
| 5 | `Chase Friends On The Road` | `Game Center markers show the rival score you're chasing.` |
| 6 | `Choose Your Retro Aesthetic` | `Switch between pocket-console green and LCD handheld styles anytime.` |
| 7 | `Customize Your Experience` | `Tune controls, haptics, volume, and visuals to fit your style.` (`Customise` on en-GB/en-AU) |

> **Export status (2026-07-17):** Source `data.plist` copy is synced for iPhone, iPad, Mac, and Apple Watch via the sync script. iPhone has English-variant JPEG exports; `es-ES`, `es-MX`, and `ca` must be re-exported with the tightened copy above. iPad and Mac need full locale exports.

## 4.3 Apple Watch Screenshot Approach

- Assume **no marketing text overlays** for watch output.
- Use sequence-only storytelling:
  1. Core gameplay lane view
  2. Input interaction moment (Digital Crown/swipe)
  3. Collision/high-tension moment
  4. Pause/help/accessibility state
  5. Score/result state
- Add support explanation in ASC screenshot order notes/internal checklist, not in-image copy.

## 4.4 Platform Scope Cleanup In ScreenshotStudio

- Remove Apple TV and Apple Vision from active planning/output for now to avoid accidental scope drift.
- Keep active sets: iPhone, iPad, Mac, Apple Watch.
