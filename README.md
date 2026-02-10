# RetroRacing

Retro-style racing game for **watchOS**, **iOS**, **iPadOS**, **tvOS**, **macOS**, and **visionOS**. Built with SwiftUI, SpriteKit, and Game Center.

## Project structure

- **RetroRacingUniversal** — iOS, iPadOS, macOS app (SwiftUI). Feature folders: `App/`, `Menu/View/`, `Game/View/`, `Leaderboard/View/`, `Settings/View/`, `Auth/View/`, `Configuration/`.
- **RetroRacingWatchOS** — watchOS app.
- **RetroRacingTvOS** — tvOS app.
- **RetroRacingVisionOS** — visionOS app (coming soon).
- **RetroRacingShared** — Shared framework: game logic (SpriteKit), themes, services (leaderboard, rating, auth), models. Used by all app targets.
- **RetroRacingSharedTests** — Unit tests for shared logic (sibling of `RetroRacingShared/` in the repo).

Test and UI test targets are **siblings** of each app folder (e.g. `RetroRacingUniversalTests/`, `RetroRacingUniversalUITests/` next to `RetroRacingUniversal/`). See `Requirements/folder_structure.md` for the full layout.
Legacy folders (`RetroRacing/RetroRacing*` old pilot layouts) have been removed; the pbxproj points only to the canonical structure above.

## Requirements

- Xcode 16+
- Deployment: iOS 26+, watchOS 26+, tvOS 26+, macOS 26+, visionOS 26+

## Behaviour & Flow

- Launch and menu flow is documented in `Requirements/launch_flow.md` (game-base + full-screen menu overlay on Universal and tvOS).
- Accessibility requirements, including reduce motion, VoiceOver, and navigation expectations, are documented in `Requirements/accessibility.md`.

## Build and run

1. Open `RetroRacing/RetroRacing.xcodeproj`.
2. Pick a scheme: **RetroRacingUniversal**, **RetroRacingWatchOS**, **RetroRacingTvOS**, **RetroRacingVisionOS**.
3. Choose a destination and run (⌘R).

## Run tests

In Xcode: choose a test scheme (e.g. **RetroRacingSharedTests**, **RetroRacingUniversalTests**) and run tests (⌘U). From the command line, use `xcrun xcodebuild test` with the desired scheme and destination (e.g. `-scheme RetroRacingSharedTests -destination "platform=iOS Simulator,name=iPhone 16"`).

## Guidelines for contributors

Read **AGENTS.md** and the docs in **Requirements/** before changing behaviour or architecture.
