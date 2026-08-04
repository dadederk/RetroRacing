# Screenshot Assets & Storyboard

Part of [App Store docs hub](../README.md).

Last updated: 2026-08-03

**Status:** localized base captures via `./retrorapid screenshots capture`. Studio **export** and Connect **upload** stay **manual**.

**Ops (capture / install / refresh):** [`08-locale-expansion.md`](08-locale-expansion.md) · **Fixtures:** [`Requirements/screenshot_capture.md`](../../Requirements/screenshot_capture.md)

## Studio project

- [RetroRapid.screenshotstudio/](../RetroRapid.screenshotstudio/) — iPhone / iPad / Mac / Apple Watch
- Overlay copy source: `Scripts/Sources/RetroRacingAutomationCore/ScreenshotStudioWorkflow.swift`
- After copy edits: `./retrorapid screenshots sync` · verify: `./retrorapid screenshots sync --check`

## Locales

| Kind | Locales |
|---|---|
| **Source capture** | `en-US`, `de-DE`, `nl-NL`, `it`, `fr-FR`, `fr-CA`, `es-ES`, `ca`, `ja`, `ko`, `pt-BR`, `pt-PT`, `zh-Hant`, `zh-Hans` |
| **Derived (pixel copy)** | `en-GB`/`en-AU`/`en-CA` ← `en-US`; `es-MX` ← `es-ES` |

`en-GB`/`en-AU` overlay spelling: British (`Customise…`). `en-CA` matches US. Watch overlays stay empty (sequence-only).

**Do not** let sync overwrite source-locale pixels with `en-US`. Staging: `.build/screenshot-capture/{iphone,ipad,mac,appleWatch}/`.

## Storyboard (iPhone / iPad)

Bodies ≤ ~10 English words. Mac omits SharePlay (nine slides; indices shift after 3). Watch: five sequence slides; its default gameplay uses Pocket and its theme showcase uses LCD — see capture contract.

| # | Title | English body | Purpose |
|---:|---|---|---|
| 1 | Race Through Endless Traffic | Dodge traffic and chase overtakes in a retro arcade racer. | Hook |
| 2 | Simple Controls. Pure Arcade Action | Move left. Move right. Don't crash. Deceptively simple. | How it plays |
| 3 | One Wrong Move. Game Over | One mistake ends your run. Restart fast, chase your high score! | Replay tension |
| 4 | Accessibility Front and Center | VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings. | Differentiator |
| 5 | Race Friends with SharePlay | Challenge friends for free. Countdown, compete, rematch. | SharePlay (iPhone/iPad) |
| 6 | Climb the Leaderboard | Game Center scores and friend markers keep every run competitive. | Competition |
| 7 | Customize Your Experience | Tune volume, haptics, controls… Go Cruise, Fast, or Rapid! | Personalization |
| 8 | Choose Your Retro Aesthetic | Switch between four retro eras, from Pocket to 16-Bit. | Theme |
| 9 | Unlock Retro Achievements | Earn Game Center trophies as you race and improve. | Achievements |
| 10 | Play Solo Or With Friends | Daily free plays, leaderboards, and live friend races. | Menu / breadth |

Optional PPO title variants for slides 1–4: keep body copy; test titles only if running a deliberate PPO experiment (`Endless Traffic Dodge Game`, `3-Lane Arcade Controls`, `One Mistake Ends Your Run`, `VoiceOver and Haptic Racing`).

## Platforms not in this campaign

- **visionOS / Apple TV:** do not export or market screenshots until publicly shipping (`AGENTS.md` shipping table).
- Studio `selectedPlatforms`: iPhone, iPad, Mac, Apple Watch only.
