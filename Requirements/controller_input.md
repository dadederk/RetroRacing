# Controller Input

## Overview

RetroRacing supports physical game controllers (MFI, Xbox, PlayStation) via Apple's `GameController` framework on iOS, iPadOS, macOS, and tvOS. Controller input is additive — existing controls (touch, keyboard, Siri Remote, trackpad) remain fully active alongside controller input.

Platforms in scope: iOS, iPadOS, macOS, tvOS.  
Platforms out of scope: watchOS (no GCController support), visionOS (stub).

---

## Default Behaviour

| Platform | Default directional input | Default pause |
|----------|--------------------------|---------------|
| iOS / macOS | D-pad + left stick | Start/Menu button |
| tvOS | Handled by `.onMoveCommand` (Siri Remote); not captured from controller | Handled by `.onPlayPauseCommand`; not captured from controller |

On tvOS, the system remote commands take precedence. Controller input on tvOS is limited to remapped face buttons only — no directional or menu capture — to prevent double-triggering.

---

## Button Remapping

Players can remap up to three actions to any face button or shoulder/trigger button in **Settings → Controller**:

| Action | Default binding | Remappable buttons |
|--------|----------------|-------------------|
| Move Left | D-pad left, left stick left | A, B, X, Y, Left Shoulder, Right Shoulder, Left Trigger, Right Trigger, Menu |
| Move Right | D-pad right, left stick right | Same set |
| Pause/Resume | Start/Menu | Same set |

Rules:
- One button cannot be assigned to multiple actions. Assigning a button that is already in use clears the previous assignment (last-assigned wins).
- Bindings are global — one profile applies to all connected controllers.
- There is no per-device mapping in v1.
- Remaps are additive. Default controls are never disabled.

---

## Architecture

### Protocol: `GameControllerInputSource`

```swift
public protocol GameControllerInputSource: AnyObject {
    func start(handler: @escaping @MainActor @Sendable (GameControllerAction) -> Void)
    func stop()
}
```

Injected into `GameView` at the composition root. The protocol keeps the shared view platform-agnostic. Swap the implementation for testing or new platforms without changing game logic.

### System implementation: `SystemGameControllerInputSource`

- Configured with `GameControllerPlatformConfig` (two flags: `capturesDirectionalInput`, `capturesMenuButton`).
- Observes `GCControllerDidConnect` / `GCControllerDidDisconnect` notifications.
- Attaches per-controller button handlers on connection and cleans up stick state on disconnect.
- **Remapped button binding is read from `UserDefaults` on every press** — no caching. Changes made in Settings take effect immediately without any cross-store synchronisation.

### Stick hysteresis (`StickHysteresisState`)

Prevents repeated lane moves while the stick is held:
- Trigger threshold: ±0.5
- Reset zone: ±0.2 (both sides must return before another trigger fires in the same direction)
- Hysteresis state tracked per connected controller via `ObjectIdentifier`.

### Router: `GameControllerActionRouter`

Pure function that maps `(GameControllerAction, isMenuOverlayVisible: Bool)` to `GameControllerRouteResult`:

| Action | Menu hidden | Menu visible |
|--------|------------|--------------|
| `.moveLeft` | `.moveLeft` | `.moveLeft` |
| `.moveRight` | `.moveRight` | `.moveRight` |
| `.pauseResume` | `.togglePause` | `.requestPlay` |

### Data model: `GameControllerBindingProfile`

- `leftExtraButton: GameControllerRemapButton`
- `rightExtraButton: GameControllerRemapButton`
- `pauseExtraButton: GameControllerRemapButton`
- `Codable`, `Equatable`, `Sendable`
- Mutation via `settingLeft(_:)`, `settingRight(_:)`, `settingPause(_:)` — each returns a new profile with conflicts resolved.

### Storage: `GameControllerBindingPreference`

- `storageKey = "gameControllerBindingProfile"`
- JSON-encoded `GameControllerBindingProfile` stored in `UserDefaults`.
- `currentProfile(from:)` returns `.default` on missing or corrupt data.
- `SettingsPreferencesStore` holds a `controllerBindingProfileData: Data` backing property for reactive UI updates.

---

## `GameView` Integration

`GameView` receives two new parameters:

```swift
controllerInputSource: any GameControllerInputSource
onPlayRequest: (() -> Void)?
```

- On `onAppear`: `controllerInputSource.start(handler:)` is called with a closure that routes actions via `GameControllerActionRouter`.
- On `onDisappear`: `controllerInputSource.stop()` is called before `model.tearDown()`.
- `onPlayRequest` is called when `.requestPlay` is routed (Start/Menu while menu overlay is visible).

---

## Composition Root

### Universal (iOS/macOS)

- `controllerInputSource = SystemGameControllerInputSource(platformConfig: .standard, userDefaults: userDefaults)`
- `handlePlayRequest()` is session-aware:
  - If `shouldStartGame == true` (session active): just dismiss the menu overlay.
  - If `shouldStartGame == false` (no active session): create new `sessionID`, set `shouldStartGame = true`, dismiss.

### tvOS

- `controllerInputSource = SystemGameControllerInputSource(platformConfig: .tvOS, userDefaults: userDefaults)`
- `handleControllerPlayRequest()` simply dismisses the menu without resetting the session.

---

## Settings UI

`SettingsView` shows a **Controller** section between the Controls description and the Speed section. It contains three `Picker` rows (Move Left, Move Right, Pause/Resume), each offering all `GameControllerRemapButton` cases. A footer explains the additive behaviour.

`SettingsPreferencesStore` exposes:
- `controllerLeftButtonSelection: Binding<GameControllerRemapButton>`
- `controllerRightButtonSelection: Binding<GameControllerRemapButton>`
- `controllerPauseButtonSelection: Binding<GameControllerRemapButton>`
- `selectedControllerBindingProfile: GameControllerBindingProfile` (computed, reads from observable backing data)
- `setControllerBindingProfile(_:)` (writes to both `UserDefaults` and the backing `Data` property)

---

## Localization

New string keys (English / Spanish / Catalan):

| Key | Purpose |
|-----|---------|
| `settings_controller` | Section header |
| `settings_controller_move_left` | Picker label |
| `settings_controller_move_right` | Picker label |
| `settings_controller_pause_resume` | Picker label |
| `settings_controller_footnote` | Additive behaviour note |
| `controller_button_none` | "None" option |
| `controller_button_a` … `controller_button_menu` | Button names |

Controls description strings (`settings_controls_ios`, `settings_controls_macos`, `settings_controls_tvos`) updated to mention controller support.

---

## Testing

Unit tests cover:
- `GameControllerBindingProfileTests` — defaults, setters, conflict resolution, Codable round-trip.
- `GameControllerBindingPreferenceTests` — persist/load round-trip, default fallback, corrupt data.
- `GameControllerActionRouterTests` — all routing combinations (directional + state-independent; pause with menu visible/hidden).

Manual validation required (hardware gate):
- iOS + Xbox Adaptive Controller: D-pad, Start, remapped A/B.
- tvOS + controller: Siri Remote direction unchanged, face button remaps work, Play/Pause unchanged.
- macOS + controller: D-pad/stick movement, Start pause, keyboard/mouse unchanged.

---

## Future Work (Out of Scope for v1)

- Per-device binding profiles.
- watchOS game controller support (watchOS 7+ has limited GCController but Apple Watch is not commonly used with physical controllers).
- visionOS controller support.
- Challenge-system achievements for controller-specific inputs.
