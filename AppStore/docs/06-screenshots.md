# Screenshot Assets & Storyboard

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-07-23

**Status:** source copy is `READY` (bodies tightened to ≤ ~10 words on 2026-07-17). Automated localized base captures are available via `swift run --package-path Scripts capture-app-store-screenshots`; Screenshot Studio export and ASC uploads remain `PLANNED`.

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
- iPhone, iPad, and Mac source copy uses the **ten-slide storyboard** on iPhone/iPad and **nine slides** on Mac (no SharePlay slide).
- `en-GB` and `en-AU` use British spelling in overlay copy (`Customise Your Experience`). `en-CA` matches US spelling.
- **Shared base captures:** For this submission pass, iPhone, iPad, and Mac reuse the same underlying `en-US_*` device captures for every locale. Localized overlay copy still differs by locale in `data.plist`; the sync script fans out each available base capture to `en-GB`, `en-AU`, `en-CA`, `es-ES`, `es-MX`, and `ca`.
- iPhone has all seven `en-US` JPEG source captures synced to every locale; slide 5 uses the Game Center friend-marker capture.
- iPad has locale manifests; run `./retrorapid screenshots capture --platform ipad` to generate base captures, then rerun sync to fan them out to every locale.
- Mac source plist has seven slides with filled Spanish/Catalan copy. Run `./retrorapid screenshots capture --platform mac --slides 5,6` if `en-US_5.png` and `en-US_6.png` are still missing, then rerun sync.
- iPad and Mac slide 5 copy is ready, but the source captures should be visually checked after export to ensure the screenshot actually shows the friend-marker moment.
- Apple Watch stays **sequence-first** with empty overlay text in Screenshot Studio. Capture base `en-US` sequence shots with `./retrorapid screenshots capture --platform watch` (Apple Watch Ultra 3 simulator, five slides).
- Re-sync copy and manifests after edits: `./retrorapid screenshots sync`
- Verify copy, manifests, and shared locale images without writing: `./retrorapid screenshots sync --check`
- Capture localized iPhone base screenshots: `./retrorapid screenshots capture`
- Capture iPad screenshots (JPEG, landscape): `./retrorapid screenshots capture --platform ipad`
- Capture Mac landscape screenshots (PNG, 2024×1568 px at 2x): `./retrorapid screenshots capture --platform mac`
- Capture Apple Watch sequence screenshots (JPEG, Ultra 3, seven source locales + derived copies; marketing clock opt-in via `--status-bar-override`): `./retrorapid screenshots capture --platform watch`

- The capture CLI runs **7 source locales** (`en-US`, `de-DE`, `nl-NL`, `it`, `fr-FR`, `es-ES`, `ca`) and duplicates pixels for `en-GB`, `en-AU`, `en-CA`, and `es-MX`. Screenshot Studio overlay copy still differs by locale in `data.plist`.
- iPhone staging: `.build/screenshot-capture/iphone/` (JPEG). iPad staging: `.build/screenshot-capture/ipad/` (JPEG). Mac staging: `.build/screenshot-capture/mac/` (PNG). Apple Watch staging: `.build/screenshot-capture/appleWatch/` (JPEG). Screenshot Studio Mac layouts use landscape orientation.
- Install previously staged captures without re-running simulators: `swift run --package-path Scripts capture-app-store-screenshots --install-only --staging-dir .build/screenshot-capture`
- Screenshot Studio `selectedPlatforms` should match shipping platforms only (iPhone, iPad, Mac, Apple Watch). Park Apple TV and Apple Vision until those products ship publicly.

### Approved Screenshot Storyboard (source copy)

Canonical source: `Scripts/Sources/RetroRacingAutomationCore/ScreenshotStudioWorkflow.swift`. Regenerate `data.plist` after edits with `swift run --package-path Scripts sync-screenshot-studio-localizations`; verify without writing via `--check`. This is the approved story for iPhone, iPad, and Mac — keep all localized exports aligned with this order.

Bodies target **≤ ~10 words** in English — one concrete beat per slide, not a second paragraph. Translated bodies may run a word or two longer, which is expected for Romance-language expansion.

| # | Title | English body (≤ ~10 words) | Purpose |
|---:|---|---|---|
| 1 | `Race Through Endless Traffic` | `Dodge traffic and chase overtakes in a retro arcade racer.` | Hook: what the game is. |
| 2 | `Simple Controls. Pure Arcade Action` | `Move left. Move right. Don't crash. Deceptively simple.` | Clarity: how it plays. |
| 3 | `One Wrong Move. Game Over` | `One mistake ends your run. Restart fast, chase your high score!` | Tension: why it is replayable. |
| 4 | `Accessibility Front and Center` | `VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings.` | Differentiator: inclusive play without leading only with accessibility. |
| 5 | `Race Friends with SharePlay` | `Challenge friends for free. Countdown, compete, rematch.` | SharePlay differentiator (iPhone/iPad only). |
| 6 | `Climb the Leaderboard` | `Game Center scores and friend markers keep every run competitive.` | Game Center competition. |
| 7 | `Customize Your Experience` | `Tune volume, haptics, controls… Go Cruise, Fast, or Rapid!` | Personalization (`Customise` on en-GB/en-AU). |
| 8 | `Choose Your Retro Aesthetic` | `Switch between pocket-console green and LCD handheld styles.` | Theme proof on pocket-green gameplay. |
| 9 | `Unlock Retro Achievements` | `Earn Game Center trophies as you race and improve.` | Achievements breadth. |
| 10 | `Play Solo Or With Friends` | `Daily free plays, leaderboards, and live friend races.` | Menu breadth / ASO (`Customise` N/A). |

### Screenshot Title ASO Variants (First Three Slides)

Keep the warm body copy above. Industry ASO tools report screenshot-text indexing, but Apple does not publicly guarantee OCR ranking weight. Treat these as conversion-first PPO variants with possible search benefit, not as confirmed keyword fields.

If the first PPO test needs more direct titles, test these against the default titles without changing the overall story order:

| # | Default title | ASO title candidate | Notes |
|---:|---|---|---|
| 1 | `Race Through Endless Traffic` | `Endless Traffic Dodge Game` | More direct mechanic/category wording. |
| 2 | `Simple Controls. Pure Arcade Action` | `3-Lane Arcade Controls` | Reinforces the lane mechanic without repeating the approved visible metadata. |
| 3 | `One Wrong Move. Game Over` | `One Mistake Ends Your Run` | Tension/replay hook with searchable arcade phrasing. |
| 4 | `Accessibility Front and Center` | `VoiceOver and Haptic Racing` | Accessibility differentiator with searchable terms; keep on slide 4, not slide 1. |

Watch screenshots:

- Keep them sequence-first unless there is a clean, legible watch overlay style.
- Recommended order: gameplay, Digital Crown/control moment, speed/tension, accessibility/help, result/high score.
- If overlay text is used, keep it extremely short and localized.

Mac screenshots:

- Mac uses nine slides: same story as iPhone/iPad except **no SharePlay slide** (indices shift after slide 3).
- Append achievements + menu captures at slides 7–8 after refreshing iPhone/iPad base captures.

Apple Vision:

- The public App Store listing currently exposes a visionOS app, but the shipping target is a "Coming Soon" placeholder.
- Do not mention Apple Vision in description, promotional text, or screenshots until gameplay is functional.
- Decide separately whether to remove the visionOS version from sale or complete the experience. This is a product/distribution issue, not an ASO wording problem.

Apple TV:

- Do not export or upload Apple TV screenshots until tvOS is publicly supported.
- Keep tvOS ASO work in a separate launch plan so it does not dilute the current App Store promise.
