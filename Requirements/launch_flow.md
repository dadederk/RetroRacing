# Launch & Menu Flow

## Overview

RetroRacing uses a **game-base + menu-overlay** launch flow on Universal (iOS, iPadOS, macOS) and tvOS:

- The app’s root view is `GameView`.
- `MenuView` is presented as a **full-screen modal overlay** on top of the game.
- The SpriteKit scene **does not start** until the menu overlay is dismissed via **Play**.

This document describes the session model, how the overlay interacts with gameplay, and platform expectations.

## Session & State Model

- **Session**: A single continuous run of gameplay in `GameScene` (from start until Game Over or Finish).
- **Session identity**:
  - The Universal and tvOS apps track a `sessionID` in their `App` entry types.
  - Changing `sessionID` forces `GameView` to be rebuilt, creating a fresh `GameScene`.
- **Start conditions**:
  - Initial launch: `GameView` is created with `shouldStartGame = false`.
  - `MenuView` is presented in a `.fullScreenCover` on top of `GameView`.
  - When the user taps **Play**, the overlay dismisses and `shouldStartGame` flips to `true`.
  - `GameViewModel.setupSceneIfNeeded` guards on `shouldStartGame`; the SpriteKit scene is created only after the overlay has dismissed.

### Game Over & Finish

- When the player loses all lives, `GameViewModel.handleCollision` sets `hud.showGameOver = true`.
- A shared game-over modal (`GameOverView`) is presented in a `.sheet` and shows score context:
  - Uses a single navigation-toolbar title (`Well played`) to provide native heading semantics (no duplicated in-content title).
  - New record: **Previous best** and **New record** lines.
  - Not a new record: **Score** and **Best** lines.
- The game-over modal presents **Restart** and **Finish**:
  - **Restart**: calls `restartGame()` on the existing scene (same session).
  - **Finish**:
    - First dismisses the game-over sheet.
    - Only after sheet dismissal completes, triggers the `onFinishRequest` callback from `GameView` into the app entry point.
    - The app entry point:
      - Sets `shouldStartGame = false`.
      - Generates a new `sessionID` to rebuild `GameView` with a fresh session.
      - Presents the menu overlay again (`isMenuPresented = true`).

## Overlay Behaviour

### Initial Launch

- `isMenuPresented = true`, `shouldStartGame = false`.
- `GameView` is visible under the overlay but **no scene is created** yet.
- Tapping Play triggers:
  - `shouldStartGame = true` is set **before** dismissing the overlay.
  - `isMenuPresented = false` dismisses the menu.
  - `GameView` rebuilds with `shouldStartGame = true`.
  - `GameViewModel.setupSceneIfNeeded` creates the scene on the next layout pass.

### Opening Menu from Gameplay (optional)

- `GameView` exposes an optional `onMenuRequest` callback.
- App entry points can wire this to re-present the menu overlay during gameplay (e.g. via an in-game Menu button).
- The in-game menu control uses the `xmark` symbol and pauses gameplay immediately on tap, before presentation state changes propagate.
- When the overlay is presented while a session is running:
  - `GameView` receives an `isMenuOverlayPresented` binding.
  - `GameView` calls `GameViewModel.setOverlayPause(isPresented:)`.
  - When `isPresented == true`, gameplay is paused.
  - When `isPresented == false`, gameplay resumes **only if the user did not explicitly pause** the game via the Pause button.

### Pausing for Overlay

- Overlay-driven pause is **separate** from user-driven pause:
  - `PauseState.scenePaused` tracks whether `GameScene` is paused.
  - `PauseState.isUserPaused` tracks whether the pause was explicitly requested by the player.
- `GameViewModel.setOverlayPause(isPresented:)`:
  - On **present**: calls `scene.pauseGameplay()`.
  - On **dismiss**: calls `scene.unpauseGameplay()` **only when** `isUserPaused == false`.
  - This avoids unpausing a game that the user explicitly paused before opening the menu.
- `GameScene` tracks an overlay pause lock; deferred start-audio completion must not clear pause while that lock is active.

## Platform Behaviour

### Universal (iOS, iPadOS, macOS)

- Root: `GameView` (universal style).
- Menu: `MenuView` (universal style) in a `.fullScreenCover`.
- Launch:
  - Always starts with menu overlay visible.
  - Play dismisses the overlay and starts gameplay.
- Finish:
  - Resets to pre-game state (new session) and shows the menu overlay again.
- Menu button during gameplay:
  - Supported via `onMenuRequest` and `showMenuButton` in `GameView`.
  - Enabled per-platform from the app entry point (e.g. iPad/macOS only).

### tvOS

- Follows the **same pattern** as Universal:
  - Root: `GameView` (tvOS style).
  - Overlay: `MenuView` (tvOS style) in `.fullScreenCover`.
- Remote:
  - Directional pad mapped to movement via `onMoveCommand`.
  - Play/Pause button mapped to the pause toggle.
- Menu overlay pauses gameplay under the hood using the same overlay pause mechanics.

### Other Platforms

- watchOS and future visionOS flows may continue to use a menu-first pattern or adopt the overlay model as needed.
- The shared view API (`GameView` and `MenuView`) supports both patterns:
  - **Menu-first navigation**: `MenuView` pushes `GameView` via `NavigationStack`.
  - **Game-base + overlay**: app entry uses `GameView` as root and presents `MenuView` in a full-screen cover.

## Accessibility Considerations

- **Play-only dismiss**:
  - The menu overlay is non-interactively dismissible; `.interactiveDismissDisabled(true)` ensures users exit via explicit controls.
  - VoiceOver should surface the Play button clearly as the way to start the game.
- **Pause while hidden**:
  - When the menu overlay is visible, gameplay is paused to avoid background activity that users cannot see.
  - The Pause button remains the primary affordance for user-initiated pause; overlay pause is transparent to users.
- **Game Over → Finish**:
  - After Finish, users land back on the menu overlay in a clean pre-game state.
  - VoiceOver users should experience a clear transition announcement from the gameplay screen back to the menu.

## Testing Notes

- Verify:
  - Initial launch shows the menu overlay and does not start gameplay until Play.
  - Play after launch starts a new session.
  - Game Over → Finish returns to the menu and resets the session.
  - Overlay opened during gameplay pauses the scene and resumes correctly when dismissed.
  - Opening the menu from gameplay pauses immediately (no ongoing background grid ticks, move haptics, or repeated `bip` playback).
  - User-initiated pauses are not overridden by overlay dismissal.
  - VoiceOver focus and announcements behave sensibly when the overlay appears and disappears.
