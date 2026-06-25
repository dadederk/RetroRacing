# RetroRapid!

**RetroRapid!** is a retro-style arcade racing game for Apple platforms. The repository and Xcode project use the technical name **RetroRacing**; the user-facing brand is **RetroRapid!**.

Built with SwiftUI, SpriteKit, and Game Center.

## Platform matrix

| Platform | Xcode target | Public App Store |
|---|---|---|
| iPhone / iPad / macOS | **RetroRacingUniversal** | Shipping |
| Apple Watch | **RetroRacingWatchOS** | Shipping |
| tvOS | **RetroRacingTvOS** | Built, not publicly listed |
| visionOS | **RetroRacingVisionOS** | Public placeholder ("Coming Soon") |

See [`AppStore/docs/02-listing-snapshot.md`](AppStore/docs/02-listing-snapshot.md) for live listing facts.

## Project structure

- **RetroRacingUniversal** — iOS, iPadOS, macOS app (SwiftUI). Feature folders: `App/`, `Menu/View/`, `Game/View/`, `Leaderboard/View/`, `Settings/View/`, `Auth/View/`, `Configuration/`.
- **RetroRacingWatchOS** — watchOS app.
- **RetroRacingTvOS** — tvOS app.
- **RetroRacingVisionOS** — visionOS app (coming soon).
- **RetroRacingShared** — Shared framework: game logic (SpriteKit), themes, services (leaderboard, rating, auth), models. Used by all app targets.
- **RetroRacingSharedTests** — Unit tests for shared logic (sibling of `RetroRacingShared/` in the repo).

Test and UI test targets are **siblings** of each app folder (e.g. `RetroRacingUniversalTests/`, `RetroRacingUniversalUITests/` next to `RetroRacingUniversal/`). See [`Requirements/folder_structure.md`](Requirements/folder_structure.md) for the full layout.
Legacy folders (`RetroRacing/RetroRacing*` old pilot layouts) have been removed; the pbxproj points only to the canonical structure above.

## Requirements

- Xcode 26+
- Deployment: iOS 26+, watchOS 26+, tvOS 26+, macOS 26+, visionOS 26+

## Behaviour & Flow

- Launch and menu flow is documented in [`Requirements/launch_flow.md`](Requirements/launch_flow.md) (game-base + full-screen menu overlay on Universal and tvOS).
- Accessibility requirements, including reduce motion, VoiceOver, and navigation expectations, are documented in [`Requirements/accessibility.md`](Requirements/accessibility.md).

## Build and run

1. Open `RetroRacing/RetroRacing.xcodeproj`.
2. Pick a scheme: **RetroRacingUniversal**, **RetroRacingWatchOS**, **RetroRacingTvOS**, **RetroRacingVisionOS**.
3. Choose a destination and run (⌘R).

## Run tests

In Xcode: choose the **RetroRacingUniversal** scheme and run tests (⌘U).
From the command line, use `swift run --package-path Scripts run-tests`; add
`--dry-run` to inspect the resolved commands or `--destination <value>` to
select another simulator.

## Guidelines for contributors

Read **AGENTS.md** and route feature work through [`Requirements/INDEX.md`](Requirements/INDEX.md) before changing behaviour or architecture.
