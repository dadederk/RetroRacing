# Folder Structure

## Overview

RetroRacing uses a **top-level folder per target** and **feature-based layout** inside each target. This document describes the target layout and the suggested order for restructure.

## Target Top-Level Layout

| Current folder / target              | Target top-level folder   |
| ------------------------------------ | ------------------------- |
| `RetroRacing/` (iOS + macOS app)     | **RetroRacingUniversal**   |
| `RetroRacing for watchOS Watch App/` | **RetroRacingWatchOS**     |
| `RetroRacing for tvOS/`              | **RetroRacingTvOS**        |
| `RetroRacing for visionOS/`          | **RetroRacingVisionOS**    |
| `RetroRacingShared/`                 | **RetroRacingShared**      |

Test/UI test targets are siblings of each app folder (e.g. `RetroRacingUniversalTests/`, `RetroRacingUniversalUITests/` next to `RetroRacingUniversal/`). With `PBXFileSystemSynchronizedRootGroup`, placing test folders inside the app folder would cause the app target to compile test sources unless membership exceptions are set in Xcode for those subfolders.

## Feature-Based Layout Inside Each App

One folder per feature; under each feature, subfolders by role: **View**, **Model** (if any), **Configuration** (if feature-specific).

### RetroRacingUniversal (iOS + macOS)

- **App/** – `RetroRacingApp.swift` (composition root)
- **Configuration/** – `LeaderboardConfigurationUniversal`, `AuthenticationPresenterUniversal`, `RatingServiceProviderUniversal`, `RatingServiceProviderMac`
- **Menu/** – `View/MenuView.swift`
- **Settings/** – `View/SettingsView.swift`
- **Game/** – `View/GameView.swift`, `View/GameView+GameControl.swift`, `View/GameView+Layout.swift`, `View/GameView+SceneLifecycle.swift`
- **Leaderboard/** – `View/LeaderboardView.swift`
- **Auth/** – `View/AuthViewControllerWrapper.swift`
- **Assets.xcassets/**, **Localizable.xcstrings** – at root or under App

### RetroRacingTvOS

- **App/** – app entry
- **Configuration/** – `LeaderboardConfigurationTvOS`, `RatingServiceProviderTvOS`
- **Menu/** – `View/tvOSMenuView.swift`
- **Settings/** – `View/tvOSSettingsView.swift`
- **Game/** – `View/tvOSGameView.swift`
- **Leaderboard/** – `View/tvOSLeaderboardView.swift`
- **Assets.xcassets/** at root

### RetroRacingWatchOS

- **App/** – app entry
- **Menu/** – `View/ContentView.swift` (main menu)
- **Settings/** – `View/SettingsView.swift`
- **Game/** – `View/WatchGameView.swift`
- **Assets.xcassets/**, **Localizable.xcstrings**

### RetroRacingVisionOS

- **App/** – app entry, `ContentView.swift`
- Same feature names and View/ subfolders as features are added.

### RetroRacingShared (feature-based)

- **Support/** or root – `RetroRacingShared.swift`, `GameLocalizedStrings.swift`, `Localizable.xcstrings`
- **Game/** – `GameScene.swift`, `GameSceneDelegate.swift`, `GameScene+Grid.swift`, `GameScene+Effects.swift`
- **Game/Model/** – `GameState.swift`, `GridState.swift`, `GridStateCalculator.swift`, `RandomSource.swift` (game logic models)
- **Theme/** – `GameTheme.swift`, `ClassicTheme.swift`, `PocketTheme.swift`, `ThemeManager.swift`, `Color+SKColor.swift`
- **Services/** – `Protocols/`, `Implementations/` (Leaderboard, Rating, Auth)
- **Extensions/** – `ImageLoader.swift`, `SKNode+Utilities.swift`
- **Logging/** – `AppLog.swift`
- **Resources/**, **Assets.xcassets/** – unchanged

## File Naming Consistency

- Prefer the same file name across targets for the same feature (e.g. `MenuView.swift`, `GameView.swift`); use the **module** to distinguish.
- Extensions: keep `GameView+GameControl.swift`, `Color+SKColor.swift` next to the main type or in the same feature folder.

## Xcode Impact

- Rename **targets** and **schemes** to match the new folder names when applying the full restructure.
- Update **project.pbxproj**: target names, build product names, source roots, and file references.
- No code changes are required for moves except bundle/asset lookups that assume old paths.

## Suggested Order for Restructure

1. **Document** (this file) and agree on naming. ✅
2. **RetroRacingShared first**: move `Models/*` into `Game/Model/`, then adjust project if needed. Run tests after. ✅ Done: `Game/Model/` contains `GameState.swift`, `GridState.swift`, `GridStateCalculator.swift`, `RandomSource.swift`.
3. **One app as pilot** (e.g. RetroRacing): create Menu/, Settings/, Game/, Leaderboard/, Auth/, App/, Configuration/, move views, build and run. ✅ Done: `App/`, `Menu/View/`, `Settings/View/`, `Game/View/`, `Leaderboard/View/`, `Auth/View/` created; views and app entry moved.
4. **Apply the same layout** to tvOS, watchOS, visionOS. ✅ (folders aligned)
5. **Rename top-level folders** on disk and update Xcode project paths and targets/schemes. ✅ (legacy `RetroRacing/RetroRacing*` folders removed; pbxproj uses canonical targets)
