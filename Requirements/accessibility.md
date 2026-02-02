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

## References

- AGENTS.md – Accessibility Requirements section
- Apple HIG – Accessibility
- `/Requirements/theming_system.md` – Visual theme and contrast
