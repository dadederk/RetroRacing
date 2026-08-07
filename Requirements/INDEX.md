# Requirements Index

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Router to shipped in-app behavior contracts; plans live in `Plans/INDEX.md`, App Store operations live in `AppStore/README.md`.
- **Must not break:** Read the routed contract before implementation/review; update this index when requirement files are added, moved, or deleted.

## Purpose

Single entrypoint for shipped in-app behavior contracts. Requirements describe what the app must do. They should not carry historical reports, full runbooks, or exhaustive test inventories.

## Task Routing

| Task | Start here | Optional / operations |
|---|---|---|
| Repo layout, target folders | [folder_structure.md](folder_structure.md) | [concurrency.md](concurrency.md) |
| Launch, menu, game flow | [launch_flow.md](launch_flow.md) | [game_tutorial.md](game_tutorial.md) |
| visionOS Classic and surface-anchored spatial gameplay | [visionos_gameplay.md](visionos_gameplay.md) | [../Plans/visionos_spatial_game_plan.md](../Plans/visionos_spatial_game_plan.md) |
| SharePlay friend races | [shareplay_multiplayer.md](shareplay_multiplayer.md) | [../TechDocs/play-with-friends-shareplay.md](../TechDocs/play-with-friends-shareplay.md) |
| Game Center leaderboards | [leaderboard_implementation.md](leaderboard_implementation.md) | [game_center_social_milestones.md](game_center_social_milestones.md), [../AppStore/game-center/README.md](../AppStore/game-center/README.md) |
| Achievements | [achievements.md](achievements.md) | [special_events.md](special_events.md), [../AppStore/game-center/achievements-rollout.md](../AppStore/game-center/achievements-rollout.md) |
| Monetization, IAP, Unlimited Plays | [monetization.md](monetization.md) | [debug_simulation.md](debug_simulation.md), [../AppStore/docs/16-iap-setup.md](../AppStore/docs/16-iap-setup.md) |
| Theming, fonts, road visuals | [theming_system.md](theming_system.md) | [font_system.md](font_system.md), [road_markers.md](road_markers.md) |
| Input (touch, crown, remote, keyboard) | [input_handling.md](input_handling.md) | [controller_input.md](controller_input.md) |
| Accessibility | [accessibility.md](accessibility.md) | — |
| Audio and haptics | [audio_haptics.md](audio_haptics.md) | — |
| Localization | [localization.md](localization.md) | [../AppStore/docs/08-locale-expansion.md](../AppStore/docs/08-locale-expansion.md) |
| Logging | [logging.md](logging.md) | — |
| Rating and review prompts | [rating_system.md](rating_system.md) | — |
| About screen | [about_screen.md](about_screen.md) | — |
| tvOS parity | [tvos_parity.md](tvos_parity.md) | — |
| Testing strategy | [testing.md](testing.md) | [screenshot_capture.md](screenshot_capture.md) |
| App Store screenshot capture mode | [screenshot_capture.md](screenshot_capture.md) | [../AppStore/docs/06-screenshots.md](../AppStore/docs/06-screenshots.md) |
| Archive, TestFlight, distribution | [../AppStore/docs/15-archive-and-distribution.md](../AppStore/docs/15-archive-and-distribution.md) | [../AppStore/docs/17-xcode-cloud-releases.md](../AppStore/docs/17-xcode-cloud-releases.md), [../AppStore/docs/14-testflight-helm-upload.md](../AppStore/docs/14-testflight-helm-upload.md) |
| App Store listing, ASO, screenshots | [../AppStore/README.md](../AppStore/README.md) | [../Plans/aso/README.md](../Plans/aso/README.md) |

## Catalog

### Core Gameplay and Flow

- [launch_flow.md](launch_flow.md) — launch and menu overlay flow
- [visionos_gameplay.md](visionos_gameplay.md) — shared-engine Classic/surface-anchored visionOS game
- [game_tutorial.md](game_tutorial.md) — in-game tutorial behavior
- [tvos_parity.md](tvos_parity.md) — tvOS shared UI parity
- [shareplay_multiplayer.md](shareplay_multiplayer.md) — SharePlay friend races

### Game Center and Social

- [leaderboard_implementation.md](leaderboard_implementation.md) — leaderboards, score submit, pending replay
- [game_center_social_milestones.md](game_center_social_milestones.md) — friend-score milestones
- [achievements.md](achievements.md) — achievement catalog, progress, reporting
- [special_events.md](special_events.md) — GAAD and seasonal events

### Monetization and StoreKit

- [monetization.md](monetization.md) — play limits and Unlimited Plays
- [debug_simulation.md](debug_simulation.md) — DEBUG-only StoreKit/play-limit simulation

### Visual Design and Theming

- [theming_system.md](theming_system.md) — theme catalog and access rules
- [font_system.md](font_system.md) — semantic fonts and preferences
- [road_markers.md](road_markers.md) — road style modes and markers

### Input, Accessibility, Audio, Localization

- [input_handling.md](input_handling.md) — platform control schemes
- [controller_input.md](controller_input.md) — physical game controllers
- [accessibility.md](accessibility.md) — VoiceOver, Reduce Motion, contrast
- [audio_haptics.md](audio_haptics.md) — sound effects and haptics
- [localization.md](localization.md) — string catalog and locales

### Services, UI Chrome, Testing

- [logging.md](logging.md) — structured `AppLog` contract
- [rating_system.md](rating_system.md) — rating prompts
- [about_screen.md](about_screen.md) — about screen content and links
- [testing.md](testing.md) — test strategy and conventions
- [screenshot_capture.md](screenshot_capture.md) — screenshot capture mode and fixtures
- [concurrency.md](concurrency.md) — Swift concurrency guardrails
- [folder_structure.md](folder_structure.md) — target and feature layout

## Maintenance

- Keep requirement contracts concise and current with shipped behavior.
- Move App Store Connect, TestFlight, and upload runbooks to `AppStore/`.
- Move future work and release campaigns to `Plans/`.
- Move durable architecture explainers to `TechDocs/`.
- Use git history for historical change records.
