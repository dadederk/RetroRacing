# Screenshot Assets & Storyboard

Part of [App Store docs hub](../README.md).

Last updated: 2026-10-02

**Status:** localized base captures via `./retrorapid screenshots capture`. Studio **export** and Connect **upload** stay **manual**.

**2.0 submission check:** The existing Studio storyboard and slide 8 still say four retro eras, from Pocket to CRT. The 2.0 release configuration exposes LCD and Pocket only. Replace or omit that slide on iPhone, iPad, and Mac, then inspect the screenshots already attached to both 2.0 drafts in every locale before App Review. Do not treat this storyboard as approved 2.0 artwork until its copy and captured UI match the selected build.

On October 2, Helm readback showed complete uploads for 20 locales on iPhone (two display sizes) and Watch, 18 locales on iPad (no `pl` or `tr`), and 18 locales on Mac (no `pl` or `tr`). Each listed iPhone/iPad locale has ten images, each Watch locale has seven, and each listed Mac locale has nine. This confirms upload coverage and processing state, **not** the words or pixels shown in those images. Review current App Store Connect crops and consider adding native `pl`/`tr` iPad and Mac captures rather than relying on locale fallback.

**Ops (capture / install / refresh):** [`08-locale-expansion.md`](08-locale-expansion.md) · **Fixtures:** [`Requirements/screenshot_capture.md`](../../Requirements/screenshot_capture.md)

## Studio project

- [RetroRapid.screenshotstudio/](../RetroRapid.screenshotstudio/) — iPhone / iPad / Mac / Apple Watch
- Overlay copy source: `Scripts/Sources/RetroRacingAutomationCore/ScreenshotStudioWorkflow.swift`
- After copy edits: `./retrorapid screenshots sync` · verify: `./retrorapid screenshots sync --check`

## Locales

| Kind | Locales |
|---|---|
| **Source capture** | `en-US`, `de-DE`, `nl-NL`, `it`, `fr-FR`, `fr-CA`, `es-ES`, `es-MX`, `ca`, `ja`, `ko`, `pt-BR`, `pt-PT`, `zh-Hant`, `zh-Hans`, `tr`, `pl` |
| **Derived (pixel copy)** | `en-GB`/`en-AU`/`en-CA` ← `en-US` |

`en-GB`/`en-AU` overlay spelling: British (`Customise…`). `en-CA` matches US. Watch overlays stay empty (sequence-only).

**Do not** let sync overwrite source-locale pixels with `en-US`. Staging: `.build/screenshot-capture/{iphone,ipad,mac,appleWatch}/`.

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

## Platforms not in this campaign

- **visionOS / Apple TV:** do not export or market screenshots until publicly shipping (`AGENTS.md` shipping table).
- Studio `selectedPlatforms`: iPhone, iPad, Mac, Apple Watch only.
