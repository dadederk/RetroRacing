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
- **Score and lives:** Header labels use `accessibilityLabel` with the same formatted text as the visual (e.g. score, lives remaining) so VoiceOver users get the same information.
- **Game controls (iOS/universal):** The game screen is split into left and right touch areas. Each half is an accessibility element with label “Move left” / “Move right” and hint “Double-tap to move car left/right”, so VoiceOver users can focus each side and double-tap to move. Settings → Controls describes these and other input methods (swipe, tap half, keyboard).

## Other Dimensions

- **Dynamic Type:** Menu and UI text support Dynamic Type (e.g. `.dynamicTypeSize(.xSmall ... .xxxLarge)`); layouts should adapt.
- **High Contrast:** Theme system and requirements (see `theming_system.md`) should support increased contrast where needed.
- **Platform:** Follow platform HIG and accessibility APIs (iOS/tvOS/watchOS/macOS/visionOS) for focus, gestures, and system settings.
- **Orientation / window changes:** SpriteKit scenes must persist across rotations and size class changes without restarting gameplay. Resize the existing scene to the new square dimension and redraw the current grid state; do not recreate the scene or reset score/lives during rotation. Scenes should keep their existing `GameState` (score, lives, grid) when re-presented after a rotation.

## Navigation & Gestures

- iOS: Disable the interactive pop (edge swipe-back) gesture on the gameplay screen so horizontal drags used for car control are never intercepted by navigation. Users exit via the back button or in-game finish controls instead.

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
