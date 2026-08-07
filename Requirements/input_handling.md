# Input Handling

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Platform UI captures native input and translates it into shared game controller actions.
- **Must not break:** UI layer owns platform input; shared game logic stays platform-agnostic; watch crown uses `CrownInputProcessor`; assistive gestures are not intercepted.
- **Key files:** `GameInputAdapter`, `RacingGameController`, `WatchGameView`, `CrownGameInputAdapter`, `MacTrackpadSwipeInterpreter`, `controller_input.md`.

## Architecture

- Platform views capture native input.
- Shared adapters translate to `RacingGameController`.
- `GameScene` implements the shared controller.
- Platform differences stay in UI/adapters, not service or gameplay logic.
- Directional handlers apply the logical lane move before optional telemetry, control-button animation, and adapter-managed haptics.
- A lane-only move repositions the existing player sprite. Full grid rendering remains the fallback for missing/stale sprite state and is still used for ticks, theme/style changes, and scene resizing.

## Platform Inputs

- iOS/iPadOS:
  - touch regions and horizontal drag gestures move lanes
  - keyboard arrows move; space toggles pause
  - Direct Touch setting controls `.accessibilityDirectTouch`
  - VoiceOver Magic Tap toggles pause/resume
- watchOS:
  - Digital Crown routes through `CrownInputProcessor`
  - touch overlay respects Direct Touch
  - Magic Tap toggles pause/resume
- tvOS:
  - Siri Remote left/right swipes and clickpad-edge taps use `onMoveCommand`
  - Play/Pause toggles pause during an active race
  - Menu/Back uses `onExitCommand` and opens the finish confirmation
- macOS:
  - arrow keys move; space toggles pause
  - two-finger horizontal trackpad swipes move one lane per gesture
  - trackpad lane swipes are disabled while VoiceOver is running
- visionOS:
  - Classic uses gaze-and-pinch SwiftUI buttons for movement and pause; spatial mode uses its three visible road lanes for gaze-and-pinch movement and keeps Pause/Resume in the attached native HUD
  - Classic's shared SpriteKit square and the spatial road expose three semantic tap lanes; each spatial target spans one full 0.15 m lane across the 0.70 m road depth, and choosing a lane left or right of the player emits one discrete move toward it
  - the current lane is a no-op, while unavailable boundary directions remain disabled in native and assistive controls
  - keyboard arrows move and Space toggles pause
  - Magic Tap, named Move left/Move right actions, and an adjustable lane control use the same command path
  - Direct Touch is bounded to the road surface and never includes HUD, placement guidance, Settings, or native controls; spatial mode retains lane hover through flush road planes backed by full-lane collision volumes, installs `GestureComponent` on each lane, and has no visible Left/Right buttons
  - lane input is disabled during preflight, surface search, confirmation, recovery, return, and any non-active session state
  - renderer geometry does not own gameplay rules; see [visionos_gameplay.md](visionos_gameplay.md)
- Physical controllers:
  - see [controller_input.md](controller_input.md)

## Digital Crown Contract

- Accumulate crown deltas until `abs(delta) > 0.30`.
- Emit at most one lane move per rotation burst.
- Reset burst state after an idle debounce around 150 ms.
- Use low crown sensitivity and keep crown focus active during play.
- Haptic crown rotation stays enabled, but gameplay move haptic fires only when a move changes lane.

## Haptic Routing

- Normal touch/remote/crown movement triggers move haptic immediately when handled.
- When cue audio mode is active and lane move cue style is Haptics, adapters suppress immediate move haptic so `GameScene` can emit safe/unsafe-specific feedback.

## Accessibility

- Voice Control aliases stay limited to explicit gameplay controls.
- HUD and SpriteKit grid/cars are not interactive Voice Control targets.
- Direct Touch defaults to on where exposed and persists user overrides.
- Assistive gestures must remain available; do not let gameplay drag/swipe recognizers steal VoiceOver/macOS assistive gestures.

## Testing

- Unit tests cover rapid consecutive lane moves, stable SpriteKit node identity during lane-only moves, full-render recovery, crown processing, macOS swipe interpretation, haptic routing, keyboard bridge focus behavior, and controller routing.
- Manual validation covers watch crown feel, iOS touch/keyboard, tvOS remote, macOS keyboard/trackpad, and controller hardware.
