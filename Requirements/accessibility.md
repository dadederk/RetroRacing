# Accessibility Requirements

## Overview

RetroRacing aims for best-effort accessibility and adaptability across all platforms. This document describes the best effort we strive for. It covers reduce motion, VoiceOver/labels, and platform-specific considerations.

## Reduce Motion

The game **must** respect the user’s Reduce Motion preference:

- **SpriteKit:** Crash blink animation is replaced with a simple fade when Reduce Motion is enabled (see `GameScene+Effects.swift`). Uses `UIAccessibility.isReduceMotionEnabled` (iOS/tvOS) and `NSAccessibility.isReduceMotionEnabled` (macOS).
- **SwiftUI:** Prefer `animation(nil)` or shorter/simpler animations when the preference is set; use `@Environment(\.accessibilityReduceMotion)` where available.
- **General:** Avoid decorative motion that cannot be turned off; keep essential feedback (e.g. score, collision) available without motion.
- **Game-over celebration:** New-record treatment in the game-over modal should avoid mandatory animation; users with Reduce Motion still receive full record/best-score context.

## VoiceOver and Labels

- **UI (SwiftUI):** All interactive elements and important text use `accessibilityLabel`; use `accessibilityHint` only when it adds meaningful context beyond the label.
- **SpriteKit nodes:** Game sprites that convey meaning (player car, rival cars, crash) have `accessibilityLabel` set and `isAccessibilityElement = true` (see `GameScene+Effects.addSprite`, labels from `GameLocalizedStrings`: `player_car`, `rival_car`, `crash_sprite`).
- **Score and lives:** Header labels use `accessibilityLabel` with the same formatted text as the visual (e.g. score, lives remaining) so VoiceOver users get the same information. The helmet icon next to lives is hidden from accessibility and the lives HUD is exposed as a single combined element. Lives VoiceOver copy uses proper singular/plural localization (for example, `1 life remaining` vs `2 lives remaining`).
- **Speed alert feedback:** The speed-increase overlay appears in the last 3 points before each level step (for example, scores 97–99 before 100 and 197–199 before 200). Before each speed increase, gameplay forecasts the next 4 scoring rows and inserts empty rows only at the two lead offsets that map to the two rows directly ahead of the player at the exact speed-up moment (no already-visible cars are removed). Settings expose a selector for speed warning feedback:
  - `VoiceOver announcement`: post `speed_increase_announcement` using `AccessibilityNotification.Announcement`.
  - `Haptic`: trigger warning haptic and skip announcement.
  - `Sound`: play a dedicated warning chirp (`D4-F4-A4`, repeated twice).
  - `None`: do not emit speed warning feedback.
  - Announcement mode uses high announcement priority.
  - Availability: haptics-supported platforms expose all four options; macOS/tvOS expose announcement/sound/none.
- **Lane audio cues:** Settings include four audio feedback modes in display order: `Retro audio`, `Audio cues (lane pulses)`, `Audio cues (arpeggio)`, and `Audio cues (chord)`. In cue modes, each grid tick announces safe columns. Move cues are user-selectable as `Lane confirmation`, `Success`, `Lane + success`, or `Haptics` (safe destination -> success haptic, unsafe destination -> move haptic, no move audio cue). Start/fail sounds remain unchanged.
- **In-game help button:** Gameplay toolbars include a `?` help action (shared platforms and watchOS). It opens a help modal with controls guidance and tutorial content (audio cues, lane cue previews including safe/unsafe haptics where supported, and speed increase warning feedback previews) so users can learn without returning to Settings.
- **VoiceOver first-run tutorial:** When VoiceOver is running, the in-game help modal is auto-presented once on the first active gameplay session. This behavior is persisted per device profile and can still be overridden by opening help manually.
- **VoiceOver tutorial copy:** The help modal includes explicit VoiceOver guidance that explains the 3-lane model, left/right movement, lane-safety sounds, and the need to move quickly to avoid crashes.
- **Game controls (iOS/universal):** The game screen is split into left and right touch areas. Each half is an accessibility element with label “Move left” / “Move right” and hint “Double-tap to move car left/right”, so VoiceOver users can focus each side and double-tap to move. Settings → Controls describes these and other input methods (swipe, tap half, keyboard).
- **Direct touch controls (iOS):** Left and right gameplay touch regions are marked with `accessibilityDirectTouch(..., options: [.silentOnTouch])` so taps are handled as direct actions and VoiceOver does not speak each region during rapid gameplay input.
- **Game-over modal:** `GameOverView` is presented as a non-interactively dismissable sheet (`interactiveDismissDisabled(true)`) with explicit **Restart** and **Finish** actions. Content is wrapped in a `ScrollView` so all summary rows and actions remain reachable at large Dynamic Type sizes and in compact landscape layouts. Decorative result artwork is hidden from accessibility while score/best labels remain readable by VoiceOver.
- **Game-over typography:** Modal subtitle and speed label use body semantic typography, while score rows and actions use emphasized semantic styles from `FontPreferenceStore`. The speed label is placed between the score summary and action buttons so hierarchy stays clear at all Dynamic Type sizes.


## Conditional Defaults for Accessibility

Some settings provide **system-derived defaults** that adapt to the user's accessibility configuration, while allowing explicit user overrides.

### Pattern

Each conditional-default setting:
1. **System default:** Computed from current accessibility or system state (e.g., VoiceOver running, Dynamic Type size, Reduce Motion)
2. **User override:** Optional explicit choice that takes precedence over the system default
3. **Storage:** Persisted as either "use system default" or "user chose X" via `ConditionalDefault<Value>`

### Infrastructure

- **`ConditionalDefault<Value>`** (`RetroRacingShared/Settings/ConditionalDefault.swift`): Generic storage type for conditional defaults. Implements `ConditionalDefaultValue` protocol requiring a static `systemDefault` computed property.
- **UserDefaults integration:** `load(from:key:)` and `save(to:key:)` methods for persistence.
- **Binding support:** SettingsView uses a `Binding` that reads `effectiveValue` and writes via `setUserOverride(_:)`.

### Example: Game Difficulty

**Requirement:** Default to `.cruise` (slowest pace) when VoiceOver is running; otherwise default to `.rapid`. User can explicitly select any difficulty to override.

**Implementation:**

- `GameDifficulty` conforms to `ConditionalDefaultValue` with `static var systemDefault: GameDifficulty` that checks `UIAccessibility.isVoiceOverRunning` (iOS/tvOS/visionOS) or `NSWorkspace.shared.isVoiceOverEnabled` (macOS). watchOS currently falls back to `.rapid` because this layer does not source watchOS VoiceOver state.
- `GameDifficulty.currentSelection(from:)` loads the `ConditionalDefault<GameDifficulty>` and returns `effectiveValue`.
- `SettingsView` displays a `Picker` bound to `difficultySelection: Binding<GameDifficulty>`, which updates the conditional default and persists it.
- Settings no longer show helper rows describing VoiceOver defaults; defaults are implicit unless the user overrides.

**UI behavior:**

- When no override is stored and VoiceOver is on: picker shows Cruise.
- User selects Fast: override is stored, picker shows Fast.
- User turns VoiceOver off later: picker still shows Fast (override persists).
- To reset: future UI could offer "Use system default" button; for now, deleting the stored override returns to system default.

### Future conditional-default settings

- **Audio feedback mode:** Defaults to `Audio cues (lane pulses)` when VoiceOver is running on iOS/tvOS/visionOS/macOS; otherwise defaults to `Retro audio`. watchOS currently keeps `Retro audio` as the system default because this layer does not currently source watchOS VoiceOver state.
- **Sound effects volume:** Defaults to `100%` when VoiceOver is running; otherwise `80%`. Slider updates create an explicit override that persists across VoiceOver changes.
- **Speed warning feedback:** Defaults to `None` when VoiceOver is off. With VoiceOver on, defaults to `Haptic` on haptics-supported platforms and `VoiceOver announcement` on non-haptics platforms. Explicit user override always wins. Legacy `inGameAnnouncementsEnabled` values are migrated once (`true -> announcement`, `false -> none`).
- **Top-down view:** Default to on when large Dynamic Type is active (future feature 7.1).

## Other Dimensions

- **Dynamic Type:** Menu and UI text use semantic font APIs (`font(textStyle:)`) so system and monospaced styles track native Dynamic Type; custom retro font follows comparable growth curves via semantic relative sizing. Layouts should adapt at accessibility sizes.
- **High Contrast:** Theme system and requirements (see `theming_system.md`) should support increased contrast where needed.
- **Platform:** Follow platform HIG and accessibility APIs (iOS/tvOS/watchOS/macOS/visionOS) for focus, gestures, and system settings.
- **Orientation / window changes:** SpriteKit scenes must persist across rotations and size class changes without restarting gameplay. Resize the existing scene to the new square dimension and redraw the current grid state; do not recreate the scene or reset score/lives during rotation. Scenes should keep their existing `GameState` (score, lives, grid) when re-presented after a rotation.

## Navigation & Gestures

- iOS / iPadOS / macOS (Universal): Disable the interactive pop (edge swipe-back) gesture on the gameplay screen so horizontal drags used for car control are never intercepted by navigation. Users exit gameplay via the in-game **Finish** control, which returns to the full-screen menu overlay, or via an optional in-game **Menu** toolbar button that pauses the game and presents the same overlay.
- tvOS: Map Siri Remote directional input to left/right movement using `onMoveCommand`.
- Menu overlay: When the menu is presented as a full-screen cover on top of `GameView`, gameplay is paused under the hood and `.interactiveDismissDisabled(true)` is used so the overlay is **Play-only dismiss**. This ensures VoiceOver and switch-control users have a clear, explicit way to start or resume gameplay.

## Pause/Resume Control (Universal, watchOS, tvOS)

- Navigation toolbar includes a top-trailing pause/resume button; it must remain accessible with clear labels (`pause` / `resume` strings).
- The `?` tutorial action pauses gameplay while presented and restores state appropriately on dismiss (manual open restores prior state; auto VoiceOver open resumes only when it introduced the pause).
- Button toggles gameplay without resetting grid or score; grid/haptics stay paused while in that state.
- Keep hints minimal—label alone should be sufficient; rely on localization entries for VoiceOver output.
- VoiceOver Magic Tap (two-finger double-tap) triggers the same pause/resume toggle path as the toolbar button, including disabled-state rules during non-user pauses.
- tvOS: the Play/Pause remote button triggers the same toggle.
- watchOS: header icon toggles pause/resume; keep label present for VoiceOver.

## References

- AGENTS.md – Accessibility Requirements section
- Apple HIG – Accessibility
- `/Requirements/theming_system.md` – Visual theme and contrast
