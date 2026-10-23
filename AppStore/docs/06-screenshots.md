# Screenshot Assets & Storyboard

Part of [App Store docs hub](../README.md).

Last updated: 2026-10-22

**Status:** localized base captures via `./retrorapid screenshots capture`. Studio **export** and Connect **upload** stay **manual**.

**2.0 submission check:** The existing Studio storyboard and slide 8 still say four retro eras, from Pocket to CRT. The 2.0 release configuration exposes LCD and Pocket only. On October 6, the inaccurate slide was removed from both App Store drafts: slide 8 on all attached iPhone/iPad sets and corresponding slide 7 on Mac, 76 screenshots total. Helm readback confirms their absence. Do not re-export that historical Studio slide for 2.0. Inspect the remaining screenshots and crops in every locale before App Review.

On October 6, Helm readback showed 20 locales on iPhone (two display sizes) and Watch, 18 locales on iPad (no `pl` or `tr`), and 18 locales on Mac (no `pl` or `tr`). Each listed iPhone/iPad locale now has nine images, Watch has seven, and Mac has eight. This confirms upload coverage and processing state, **not** the words or pixels shown in those images. Review current App Store Connect crops and consider adding native `pl`/`tr` iPad and Mac captures rather than relying on locale fallback.

**Ops (capture / install / refresh):** [`08-locale-expansion.md`](08-locale-expansion.md) · **Fixtures:** [`Requirements/screenshot_capture.md`](../../Requirements/screenshot_capture.md)

## Studio project

- [RetroRapid.screenshotstudio/](../RetroRapid.screenshotstudio/) — iPhone / iPhone Duo / iPad / Mac / Apple Watch / Apple TV
- Overlay copy source: `Scripts/Sources/RetroRacingAutomationCore/ScreenshotStudioWorkflow.swift`
- After copy edits: `./retrorapid screenshots sync` · verify: `./retrorapid screenshots sync --check`

## Locales

| Kind | Locales |
|---|---|
| **Source capture** | `en-US`, `de-DE`, `nl-NL`, `it`, `fr-FR`, `fr-CA`, `es-ES`, `es-MX`, `ca`, `ja`, `ko`, `pt-BR`, `pt-PT`, `zh-Hant`, `zh-Hans`, `tr`, `pl` |
| **Derived (pixel copy)** | `en-GB`/`en-AU`/`en-CA` ← `en-US` |

`en-GB`/`en-AU` overlay spelling: British (`Customise…`). `en-CA` matches US. Watch overlays stay empty (sequence-only).

**Do not** let sync overwrite source-locale pixels with `en-US`. Staging: `.build/screenshot-capture/{iphone,iphoneDuo,ipad,mac,appleWatch,appleTv}/`.

The 20-locale model uses 17 independent sources plus three English-derived locales. `es-MX` is a source locale with Mexican Spanish in-app pixels; only `en-GB`, `en-AU`, and `en-CA` derive from `en-US`. Recapture a source locale only after its fluent reviewer approves the current digest in [`../localization/review-status.json`](../localization/review-status.json), and keep existing Studio assets until the replacements pass visual inspection.

## Storyboard (iPhone / iPad)

Bodies ≤ ~10 English words. Mac omits SharePlay (nine slides; indices shift after 3). Watch: seven sequence slides ordered as hook gameplay, game over/new-best, action gameplay, achievement unlock, LCD/theme gameplay, menu, and settings — see capture contract.

| # | Title | English body | Purpose |
|---:|---|---|---|
| 1 | Race Through Endless Traffic | Dodge traffic and chase overtakes in a retro arcade racer. | Hook |
| 2 | Simple Controls. Pure Arcade Action | Move left. Move right. Don't crash. Deceptively simple. | How it plays |
| 3 | One Wrong Move. Game Over | One mistake ends your run. Restart fast, chase your high score! | Replay tension |
| 4 | Accessibility Front and Center | VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings. | Differentiator |
| 5 | Race Friends with SharePlay | Challenge friends for free. Countdown, compete, rematch. | SharePlay (iPhone/iPad) |
| 6 | Climb the Leaderboard | Game Center scores and friend markers keep every run competitive. | Competition |
| 7 | Customize Your Experience | Tune volume, haptics, controls… Go Cruise, Fast, or Rapid! | Personalization |
| 8 | Choose Your Retro Aesthetic | Switch between four retro eras, from Pocket to CRT. | Theme; historical Studio copy, **not approved for 2.0** |
| 9 | Unlock Retro Achievements | Earn Game Center trophies as you race and improve. | Achievements |
| 10 | Play Solo Or With Friends | Daily free plays, leaderboards, and live friend races. | Menu / breadth |

Optional PPO title variants for slides 1–4: keep body copy; test titles only if running a deliberate PPO experiment (`Endless Traffic Dodge Game`, `3-Lane Arcade Controls`, `One Mistake Ends Your Run`, `VoiceOver and Haptic Racing`).

## iPhone Duo storyboard

iPhone Duo reuses the iPhone template, captions, and ten-slide story. Its base captures deliberately alternate device posture in Studio order: slides 0, 2, 4, 6, and 8 use the open inner display; slides 1, 3, 5, 7, and 9 use the closed outer display. This shows both ways to play without introducing a separate copy track.

Capture with `./retrorapid screenshots capture --platform iphoneDuo`. The workflow resolves the iOS 27.1 `iPhone Duo` simulator, captures every open slide first and every closed slide second, and pauses at each batch boundary until the operator confirms the matching Simulator pose. For open slides, the UI test prepares the deterministic app state and the host captures the active inner display directly; closed slides use the normal app capture path. Successful captures are installed into `iphoneDuo/images/`; RocketSim is not required.

## Apple TV storyboard

Apple TV follows the ten-slide sequence above with native 1920×1080 captures. It uses the TV menu/settings layouts, omits haptics from accessibility copy, and replaces the Pocket showcase with the shipping Disc theme.

| # | Title | English body | TV-specific treatment |
|---:|---|---|---|
| 4 | Accessibility Front and Center | VoiceOver, audio cues, larger text, and adaptable gameplay settings. | No haptics claim |
| 7 | Choose Your Retro Aesthetic | Explore five retro styles, from Pocket to Disc. | TV theme selector |
| 8 | Disc Style on the Big Screen | A vivid late-1990s look made for Apple TV. | Disc gameplay showcase |

All other Apple TV slides use the shared localized copy. Screenshot Studio must list `appleTv` in `selectedPlatforms` and contain ten images for each of the 20 locales before export.

## Platforms not in this campaign

- **visionOS:** do not export or market screenshots until publicly shipping (`AGENTS.md` shipping table).
