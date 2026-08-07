# tvOS Parity

## Overview

This document describes the tvOS parity work that aligns tvOS with the shared UI and functionality used on iOS/macOS while respecting tvOS platform constraints.

## Scope

- Use the shared SwiftUI Menu/Game/Settings/Leaderboard views from `RetroRacingShared/Views/`.
- Centralize app bootstrap logic (Game Center access point, audio session, font registration) in shared code.
- Replace the tvOS-unavailable `Slider` control in Settings with a focus-friendly `Picker`.
- Keep tvOS-specific input handling in the UI layer via injected adapters and SwiftUI commands.

## Shared UI

The following views live in the shared module and are used by both iOS/macOS (Universal) and tvOS:

- `MenuView`
- `GameView`
- `SettingsView`
- `LeaderboardView`

### Style Injection

Shared views use injected style structs to keep a single code path while adjusting size/spacing for tvOS:

- `MenuViewStyle`
- `GameViewStyle`
- `SettingsViewStyle`

### Input Adapter Injection

`GameView` receives a `GameInputAdapterFactory` to keep platform input in the UI layer.

- iOS/macOS: `TouchInputAdapterFactory`
- tvOS: `RemoteInputAdapterFactory`

### tvOS Availability Guards

Shared SwiftUI views must avoid tvOS-unavailable APIs by using compile-time checks in the view layer (not services). This includes:

- `DragGesture` usage in shared overlays (disabled on tvOS)
- iOS-only navigation title display modifiers (guarded to iOS only)

## Settings (tvOS)

- Settings is one full-screen destination in the menu's single `NavigationStack`, not a modal sheet. Menu/Back leaves Settings or Tutorial without Done buttons; Back at the menu root is inert and never reveals the pre-game canvas.
- Settings uses a native top tab bar for Speed, Theme, Sound, Accessibility, Controls, Purchases, About, and Debug when available. Moving focus across the tabs switches category pages without a Select press.
- Each category page uses a television-scale two-column composition: a semantic icon, title, and current-value summary on the left; a system `List` of controls on the right. Controls remain explicit actions so browsing categories cannot change preferences.
- Category controls use system `List`, `Toggle`, and navigation-link `Picker` behavior with semantic TV-scale typography.
- Theme embeds the complete selectable Style Gallery in its category page, followed by font and road-appearance controls; it does not push a gallery sub-screen.
- The Sound Effects volume control uses a `Picker` with 5% steps (0% → 100%).
- Haptics section is hidden (tvOS has no haptics).
- Direct Touch is hidden because touch-based gameplay regions do not apply to Apple TV.
- Controls description uses `settings_controls_tvos` and documents swipe/click steering, Play/Pause, Menu/Back, and game controllers.
- Controller remaps are additive aliases. D-pad/stick, Menu/Start, and B/Back keep their native move, pause, and exit behavior.
- Disc is the free/default tvOS theme because the platform has not shipped yet. Debug builds expose a local feature-flag opt-out; disabling it updates the catalog immediately and restores the CRT catalog and default for comparison and QA.
- Builds without Debug UI ignore any persisted local override and retain the Disc platform default.

## Menu (tvOS)

- Uses shared `MenuView` with `MenuViewStyle.tvOS`.
- The menu is an app-owned opaque full-screen overlay and hides and disables the underlying game while presented, while leaving it mounted for controller monitoring.
- Tutorial and Settings are labeled, single-line television-scale actions in the top-right focus section; Tutorial appears immediately before Settings and neither action overlaps the centered game title.
- Moving Up from Play focuses Tutorial; moving Down from either Tutorial or Settings focuses Play.
- Play is the preferred initial focus. Returning from Tutorial or Settings restores focus to the action that opened the destination.
- Rate App button is hidden on tvOS.
- Game Center auth receives one automatic attempt per menu instance. Dismissing the system sign-in UI must not present it again when the menu reappears; the leaderboard button remains disabled until authenticated.
- **Play with Friends** is always visible and bypasses the solo play-limit gate. It directly activates the shared Group Activity only when Apple reports an eligible FaceTime group; otherwise a localized alert explains that the player should start or join a FaceTime call. Incoming and continued sessions are observed for the app lifetime.

## Game (tvOS)

- Controller monitoring starts when `GameView` is mounted, including while the menu is covering the pre-game scene, so the first race accepts remote and game-controller input.
- Gameplay omits the Menu, Help, and Play/Pause toolbar buttons. The HUD uses substantially larger score and helmet treatments with wider side rails for TV viewing distance.
- The square gameplay canvas stays vertically centered inside the tvOS safe area, preserving comparable top and bottom margins.
- Remote left/right swipes and clickpad-edge taps use `onMoveCommand`.
- Play/Pause remote button uses `onPlayPauseCommand`.
- Menu/Back uses `onExitCommand` to pause and show a Finish Game / Keep Playing alert.
- Choosing Keep Playing restores focus to the game surface so later remote commands remain responsive.
- Keep Playing preserves an explicit user pause; Finish resets to a fresh pre-game session and returns to the menu.
- `RemoteInputAdapterFactory` drives left/right input via the shared `RemoteGameInputAdapter`.

## App Bootstrap

`AppBootstrap` (shared) provides:

- `configureGameCenterAccessPoint()`
- `configureAudioSession()`
- `registerCustomFont()`

Both Universal and tvOS apps call these at startup.

## Testing

Unit tests cover the mounted pre-game controller-listener lifecycle, platform presentation styles, vertical safe-area policy, category visibility, and shared SharePlay state transitions. tvOS UI-test launches suppress live Game Center authentication presentation so focus/navigation assertions are deterministic. tvOS UI tests cover Play, left/right remote commands, Play/Pause pause and resume, both outcomes of the Menu/Back finish-game alert, bounded Tutorial/Settings navigation, focus-driven settings tab changes, the embedded Theme gallery, menu-root Back behavior, utility-action placement, and menu focus restoration. Manual device QA covers FaceTime eligibility guidance and incoming/continued SharePlay sessions.

After changes:

```bash
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingSharedTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingUniversalTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingTvOS -destination "platform=tvOS Simulator,name=Apple TV 4K (3rd generation),OS=latest" -only-testing:RetroRacingTvOSUITests
```

## Notes

- No service-layer `#if os()` usage was added.
- View-level platform differences remain isolated to injected style and input factories.
