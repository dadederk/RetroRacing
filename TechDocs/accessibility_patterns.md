# RetroRapid Accessibility Patterns

Established patterns in the RetroRacing codebase. Match these when adding or changing accessibility. Full shipped contract: `Requirements/accessibility.md`.

## SpriteKit Labels

Meaningful sprites expose labels and participate in the accessibility tree:

```swift
playerSprite.accessibilityLabel = NSLocalizedString("player_car", comment: "Player's car")
playerSprite.isAccessibilityElement = true
```

See `GameScene+Effects.addSprite` and `GameLocalizedStrings` (`player_car`, `rival_car`, `crash_sprite`).

## Reduce Motion

Respect system Reduce Motion — simpler fades instead of decorative motion:

```swift
#if os(macOS)
if NSAccessibility.isReduceMotionEnabled { /* simple fade */ }
#else
if UIAccessibility.isReduceMotionEnabled { /* simple fade */ }
#endif
```

SwiftUI: `@Environment(\.accessibilityReduceMotion)` where available. See `GameScene+Effects.swift`.

## Score And Announcements

Post announcements for meaningful state changes when native traits are insufficient:

```swift
UIAccessibility.post(notification: .announcement,
                     argument: String(localized: "score_announcement \(score)"))
```

Speed-increase warnings use `AccessibilityNotification.Announcement` when VoiceOver announcement mode is selected.

## VoiceOver Gameplay Modes

When VoiceOver is running during active gameplay (universal shared view):

- Expose left/right touch regions; keep score/lives as read-only status.
- Hide sprite/grid and gameplay toolbar from VoiceOver in this mode.

When paused by explicit user action: switch to row-major grid exploration overlay with localized cell announcements (`No car`, `Rival car`, `Player car`, `Crash` + coordinates). Implicit pauses (crash, menus) keep direct touch active.

## Direct Touch And Voice Control

Gameplay regions use `accessibilityDirectTouch(..., options: [.silentOnTouch])` when enabled. Settings `Direct Touch` toggle uses conditional-default storage.

Voice Control input labels: `Left`, `Move left` and `Right`, `Move right` on lane controls.

## Semantic Fonts

Shared SwiftUI modals and overlays use `FontPreferenceStore` semantic fonts from environment — no hardcoded `.title`/`.body` defaults in final UI.

## Paused Grid Overlay

See `PausedGridAccessibilityOverlay` tests and `Requirements/accessibility.md` for exploration focus order and cell copy.

## What Not To Do

- Do not rely on color or sound alone for game state.
- Do not add trait words to labels when traits already convey role.
- Do not make UI changes unrelated to the accessibility task unless explicitly requested.
