# Screenshot Localization Copy (All Slides)

Part of [ASO & growth plans](README.md). Index: [retrorapid_aso_growth_plan.md](../retrorapid_aso_growth_plan.md).

Last updated: 2026-07-25
**See also:** [Current storyboard](../../AppStore/docs/06-screenshots.md) · Canonical source: `Scripts/Sources/RetroRacingAutomationCore/ScreenshotStudioWorkflow.swift` · Sync command: `./retrorapid screenshots sync`

---

## 4) Screenshot Messaging Plan

## 4.1 Positioning Rule

- Slides 1–3 should sell the game loop.
- Accessibility appears on slide 4 (after the funnel, before SharePlay).
- SharePlay is slide 5 on iPhone/iPad only; Mac skips this slide.
- Game Center competition is slide 6; customization and aesthetic proof follow; achievements and menu close the set.
- Bodies target **≤ ~10 words** in English; one beat per slide, no repeated ground. Translated bodies may run a word or two longer.

## 4.2 iPhone Caption Sequence

Current iPhone/iPad source copy uses this **ten-slide** order. Mac uses **nine slides** (no SharePlay). Locales: `en-US`, `en-GB`, `en-AU`, `en-CA`, `de-DE`, `nl-NL`, `it`, `fr-FR`, `es-ES`, `es-MX`, `ca`. Full per-locale text lives only in the canonical Swift source and generated `data.plist` files.

| # | Title (EN) | Body (EN, ≤ ~10 words) |
|---|------------|-----------|
| 1 | `Race Through Endless Traffic` | `Dodge traffic and chase overtakes in a retro arcade racer.` |
| 2 | `Simple Controls. Pure Arcade Action` | `Move left. Move right. Don't crash. Deceptively simple.` |
| 3 | `One Wrong Move. Game Over` | `One mistake ends your run. Restart fast, chase your high score!` |
| 4 | `Accessibility Front and Center` | `VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings.` |
| 5 | `Race Friends with SharePlay` | `Challenge friends for free. Countdown, compete, rematch.` |
| 6 | `Climb the Leaderboard` | `Game Center scores and friend markers keep every run competitive.` |
| 7 | `Customize Your Experience` | `Tune volume, haptics, controls… Go Cruise, Fast, or Rapid!` (`Customise` on en-GB/en-AU) |
| 8 | `Choose Your Retro Aesthetic` | `Switch between four retro eras, from Pocket to CRT.` |
| 9 | `Unlock Retro Achievements` | `Earn Game Center trophies as you race and improve.` |
| 10 | `Play Solo Or With Friends` | `Daily free plays, leaderboards, and live friend races.` |

> **Export status (2026-07-25):** Overlay copy synced via `./retrorapid screenshots sync`. Capture new base images for slides 4–5 (SharePlay + shifted friend marker), 8–9 (achievements + menu) on iPhone/iPad; Mac slides 7–8 for achievements + menu.

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
