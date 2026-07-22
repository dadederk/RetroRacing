# Requirements Index

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Router to shipped in-app behavior contracts; plans live in `Plans/INDEX.md`.
- **Must not break:** Read routed contract before implementing; update INDEX when adding/removing requirement files.

## Purpose

Single entrypoint for shipped in-app behavior contracts. Plans track remaining work (`Plans/INDEX.md`); requirements define what is already specified and how it should behave.

**Read the relevant contract before implementing or changing a feature.**

## Task routing

| Task | Start here | Optional |
|---|---|---|
| Repo layout, target folders | [folder_structure.md](folder_structure.md) | [concurrency.md](concurrency.md) |
| Launch, menu, game flow | [launch_flow.md](launch_flow.md) | [game_tutorial.md](game_tutorial.md) |
| SharePlay competitive mode | [shareplay_multiplayer.md](shareplay_multiplayer.md) | — |
| Game Center, leaderboards | [leaderboard_implementation.md](leaderboard_implementation.md) | [game_center_social_milestones.md](game_center_social_milestones.md) |
| Achievements | [achievements.md](achievements.md) | [achievements_rollout_checklist.md](achievements_rollout_checklist.md), [special_events.md](special_events.md) |
| Monetization, IAP, premium access | [monetization.md](monetization.md) | [in_app_purchases_setup.md](in_app_purchases_setup.md), [premium_access_verification.md](premium_access_verification.md) |
| Debug simulation (StoreKit) | [debug_simulation.md](debug_simulation.md) | [debug_simulation_verification.md](debug_simulation_verification.md) |
| Theming, fonts, road visuals | [theming_system.md](theming_system.md) | [font_system.md](font_system.md), [road_markers.md](road_markers.md) |
| Input (touch, crown, remote, keyboard) | [input_handling.md](input_handling.md) | [controller_input.md](controller_input.md) |
| Accessibility | [accessibility.md](accessibility.md) | — |
| Audio and haptics | [audio_haptics.md](audio_haptics.md) | — |
| Localization | [localization.md](localization.md) | — |
| Logging | [logging.md](logging.md) | — |
| Rating and review prompts | [rating_system.md](rating_system.md) | — |
| About screen | [about_screen.md](about_screen.md) | — |
| tvOS parity | [tvos_parity.md](tvos_parity.md) | — |
| Testing strategy | [testing.md](testing.md) | — |
| Archive and distribution | [archive_and_distribution.md](archive_and_distribution.md) | — |
| App Store rejection fixes | [app_store_rejection_fix.md](app_store_rejection_fix.md) | — |
| App Store listing, ASO, screenshots | [../AppStore/README.md](../AppStore/README.md) | [../Plans/aso/README.md](../Plans/aso/README.md) |

## Complete catalog

### Core gameplay and flow

- [launch_flow.md](launch_flow.md) — Launch and menu overlay flow
- [game_tutorial.md](game_tutorial.md) — In-game tutorial behavior
- [tvos_parity.md](tvos_parity.md) — tvOS shared UI parity
- [shareplay_multiplayer.md](shareplay_multiplayer.md) — SharePlay competitive mode (iOS/iPad v1)

### Game Center and social

- [leaderboard_implementation.md](leaderboard_implementation.md) — Leaderboard architecture
- [game_center_social_milestones.md](game_center_social_milestones.md) — Friend-score milestones
- [achievements.md](achievements.md) — Achievement catalog and reporting
- [achievements_rollout_checklist.md](achievements_rollout_checklist.md) — ASC rollout checklist
- [special_events.md](special_events.md) — GAAD and seasonal events

### Monetization and StoreKit

- [monetization.md](monetization.md) — Play limits and premium model
- [in_app_purchases_setup.md](in_app_purchases_setup.md) — IAP configuration
- [premium_access_verification.md](premium_access_verification.md) — Premium entitlement checks
- [debug_simulation.md](debug_simulation.md) — Debug StoreKit simulation
- [debug_simulation_verification.md](debug_simulation_verification.md) — Production isolation verification

### Visual design and theming

- [theming_system.md](theming_system.md) — Theme protocol and monetization
- [font_system.md](font_system.md) — Semantic fonts and preferences
- [road_markers.md](road_markers.md) — Road style modes and markers

### Input and controls

- [input_handling.md](input_handling.md) — Platform control schemes
- [controller_input.md](controller_input.md) — Physical game controllers

### Accessibility, audio, localization

- [accessibility.md](accessibility.md) — VoiceOver, Reduce Motion, contrast
- [audio_haptics.md](audio_haptics.md) — Sound effects and haptics
- [localization.md](localization.md) — String catalog and locales

### Platform services and UI chrome

- [logging.md](logging.md) — Structured `AppLog` contract
- [rating_system.md](rating_system.md) — App rating strategy
- [about_screen.md](about_screen.md) — About screen content and links

### Engineering and release

- [testing.md](testing.md) — Unit test strategy and conventions
- [concurrency.md](concurrency.md) — Swift concurrency patterns
- [folder_structure.md](folder_structure.md) — Target and feature layout
- [archive_and_distribution.md](archive_and_distribution.md) — Archive and distribution
- [app_store_rejection_fix.md](app_store_rejection_fix.md) — Past rejection resolutions

## Document lifecycle

### Before implementation

1. Route through this index to the relevant contract(s)
2. Read specifications, edge cases, and constraints
3. Check related features or dependencies

### During implementation

1. Follow patterns and guidelines in requirements
2. Document discovered edge cases
3. Note deviations from the original spec (with rationale)

### After implementation

1. Update the requirement file to reflect reality
2. Add implementation notes and gotchas
3. Create new requirement files for new features
4. Keep testing strategies current

## Maintenance

- After major features: ensure specs match implementation
- Before refactoring: check affected requirements
- When bugs are found: document edge cases or clarifications
- Quarterly: audit for outdated information

---

**Last updated**: 2026-07-22
