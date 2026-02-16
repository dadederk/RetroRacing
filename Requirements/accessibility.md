# Accessibility Requirements

## Overview

RetroRacing aims for best-effort accessibility and adaptability across all platforms. This document describes the best effort we strive for. It covers reduce motion, VoiceOver/labels, and platform-specific considerations.

## Reduce Motion

The game **must** respect the user’s Reduce Motion preference:

- **SpriteKit:** Crash blink animation is replaced with a simple fade when Reduce Motion is enabled (see `GameScene+Effects.swift`). Uses `UIAccessibility.isReduceMotionEnabled` (iOS/tvOS) and `NSAccessibility.isReduceMotionEnabled` (macOS).
- **SwiftUI:** Prefer `animation(nil)` or shorter/simpler animations when the preference is set; use `@Environment(\.accessibilityReduceMotion)` where available.
- **General:** Avoid decorative motion that cannot be turned off; keep essential feedback (e.g. score, collision) available without motion.

## VoiceOver and Labels

- **UI (SwiftUI):** All interactive elements and important text use `accessibilityLabel`; use `accessibilityHint` only when it adds meaningful context beyond the label.
- **SpriteKit nodes:** Game sprites that convey meaning (player car, rival cars, crash) have `accessibilityLabel` set and `isAccessibilityElement = true` (see `GameScene+Effects.addSprite`, labels from `GameLocalizedStrings`: `player_car`, `rival_car`, `crash_sprite`).
- **Score and lives:** Header labels use `accessibilityLabel` with the same formatted text as the visual (e.g. score, lives remaining) so VoiceOver users get the same information. The helmet icon next to lives is hidden from accessibility and the lives HUD is exposed as a single combined element. Lives VoiceOver copy uses proper singular/plural localization (for example, `1 life remaining` vs `2 lives remaining`).
- **Speed alert announcement:** The speed-increase overlay appears in the last 3 points before each level step (for example, scores 97–99 before 100 and 197–199 before 200). Before each speed increase, gameplay forecasts the next 4 scoring rows and inserts empty rows only at the two lead offsets that map to the two rows directly ahead of the player at the exact speed-up moment (no already-visible cars are removed). When the overlay appears (`showSpeedAlert`), VoiceOver posts an explicit announcement using `speed_increase_announcement` (for example, “Hey Ho! Speed increasing!”). This announcement is skipped when `inGameAnnouncementsEnabled` is disabled in Settings.
- **Game controls (iOS/universal):** The game screen is split into left and right touch areas. Each half is an accessibility element with label “Move left” / “Move right” and hint “Double-tap to move car left/right”, so VoiceOver users can focus each side and double-tap to move. Settings → Controls describes these and other input methods (swipe, tap half, keyboard).
- **Direct touch controls (iOS):** Left and right gameplay touch regions are marked with `accessibilityDirectTouch(..., options: [.silentOnTouch])` so taps are handled as direct actions and VoiceOver does not speak each region during rapid gameplay input.

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
- Button toggles gameplay without resetting grid or score; grid/haptics stay paused while in that state.
- Keep hints minimal—label alone should be sufficient; rely on localization entries for VoiceOver output.
- tvOS: the Play/Pause remote button triggers the same toggle.
- watchOS: header icon toggles pause/resume; keep label present for VoiceOver.

## References

- AGENTS.md – Accessibility Requirements section
- Apple HIG – Accessibility
- `/Requirements/theming_system.md` – Visual theme and contrast
