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

- The Sound Effects volume control uses a `Picker` with 5% steps (0% → 100%).
- Haptics section is hidden (tvOS has no haptics).
- Controls description uses `settings_controls_tvos`.

## Menu (tvOS)

- Uses shared `MenuView` with `MenuViewStyle.tvOS`.
- Rate App button is hidden on tvOS.
- Game Center auth is started on appear; leaderboard button is disabled until authenticated.

## Game (tvOS)

- Remote directional input uses `onMoveCommand`.
- Play/Pause remote button uses `onPlayPauseCommand`.
- `RemoteInputAdapterFactory` drives left/right input via the shared `RemoteGameInputAdapter`.

## App Bootstrap

`AppBootstrap` (shared) provides:

- `configureGameCenterAccessPoint()`
- `configureAudioSession()`
- `registerCustomFont()`

Both Universal and tvOS apps call these at startup.

## Testing

After changes:

```bash
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingSharedTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingUniversalTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

## Notes

- No service-layer `#if os()` usage was added.
- View-level platform differences remain isolated to injected style and input factories.
