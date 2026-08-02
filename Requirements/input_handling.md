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
  - Siri Remote movement uses `onMoveCommand`
  - Play/Pause toggles pause
- macOS:
  - arrow keys move; space toggles pause
  - two-finger horizontal trackpad swipes move one lane per gesture
  - trackpad lane swipes are disabled while VoiceOver is running
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

- Unit tests cover crown processing, macOS swipe interpretation, haptic routing, keyboard bridge focus behavior, and controller routing.
- Manual validation covers watch crown feel, iOS touch/keyboard, tvOS remote, macOS keyboard/trackpad, and controller hardware.
