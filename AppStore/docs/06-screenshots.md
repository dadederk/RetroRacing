# Screenshot Assets & Storyboard

Part of [App Store docs hub](../README.md).

Last updated: 2026-10-26

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

## Appearance pattern

All platforms and source locales alternate appearance in Studio order: even-numbered slides are light and odd-numbered slides are dark. Run each platform as two grouped capture passes so the installed images keep that pattern. iPhone Duo combines the same appearance alternation with its existing open-even and closed-odd pose sequence.

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

Apple TV follows the same ten-step narrative arc with native 3840×2160 captures, but its English captions are written specifically for the big-screen experience. They lead with the feeling and outcome of play, then use searchable arcade-racing terms naturally. The TV sequence uses its native menu/settings layouts, omits haptics from accessibility copy, and replaces the Pocket showcase with the Cartridge theme so it contrasts with the Disc hook gameplay.

The Accessibility settings slide uses Accessibility 5, the largest supported Dynamic Type size, so the screenshot demonstrates the app's large-text layout. Derived English locales reuse the `en-US` pixels through screenshot sync.

| # | English title | English body | Story role |
|---:|---|---|---|
| 1 | Bring Retro Racing to the Big Screen | Dodge traffic, chase overtakes, and feel every close call. | Big-screen hook |
| 2 | Every Run Gets Faster | Stay sharp as the speed climbs and traffic closes in. | Rising tension |
| 3 | Crash. Restart. Beat Your Best. | Instant restarts keep your next high score within reach. | One-more-run loop |
| 4 | Play the Way That Works for You | VoiceOver, audio cues, and larger text keep racing within reach. | Inclusive play |
| 5 | Turn the Couch Into a Starting Grid | Race friends free with SharePlay, then rematch in seconds. | Live friend racing |
| 6 | Make Every Overtake Personal | Friend markers turn every run into a score-chasing rivalry. | Personal competition |
| 7 | Make the Arcade Yours | Choose five retro styles and race the one you love. | Personal expression |
| 8 | Bring Back the 8-Bit Rush | Cartridge style fills the big screen with bold arcade energy. | Cartridge showcase |
| 9 | Turn Great Runs Into Trophies | Unlock Game Center achievements as your racing skills grow. | Progress and mastery |
| 10 | Your Next Run Starts Here | Play solo, race friends, or chase leaderboard glory. | Invitation to play |

All 17 source locales now use benefit-led transcreations of this story, with
regional register preserved for `fr-CA`, `es-MX`, `pt-BR`, and `pt-PT`.
The three derived English locales reuse `en-US` copy. Fluent approval remains
tracked as `NEEDS_REVIEW` in
[`localization/review-status.json`](../localization/review-status.json); do not
describe these transcreations as native-approved until that record changes.
Screenshot Studio must list `appleTv` in `selectedPlatforms` and contain ten
images for each of the 20 locales before export.

## Platforms not in this campaign

- **visionOS:** do not export or market screenshots until publicly shipping (`AGENTS.md` shipping table).
