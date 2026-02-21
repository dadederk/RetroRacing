# Input Handling

## Overview

RetroRacing captures platform-specific input at the UI layer and translates it into shared game actions. Input handling prioritizes responsiveness, consistency, and accessibility while keeping platform differences out of shared game logic.

## Architecture

- **UI layer owns input**: Each platform view/controller captures its native input (touch, crown, remote, keyboard).
- **Shared adapters**: UI passes events through `GameInputAdapter` implementations in `RetroRacingShared`.
- **Shared controller**: Adapters call `RacingGameController` (`GameScene` implements this).
- **No platform flags in shared code**: Platform differences stay in platform UI.

## Implementation Details

### watchOS Digital Crown (Legacy Feel)

- **Processor**: `LegacyCrownInputProcessor` in `RetroRacingShared` replicates the old `WKCrownDelegate` behavior.
- **Threshold**: Crown deltas are accumulated and movement triggers when `abs(accumulatedDelta) > 0.30` (reduces accidental lane changes while still allowing slower turns to register).
- **Gating**: Only one move per rotation burst. Additional deltas are ignored until the crown is idle.
- **Idle detection**: SwiftUI has no direct idle callback, so `WatchGameView` uses a debounced reset (`~150ms`) to simulate `crownDidBecomeIdle`.
- **Delta source**: `digitalCrownRotation` deltas are computed from successive value changes (no manual reset), keeping the stream continuous.
- **SwiftUI crown sensitivity**: `WatchGameView` uses `.digitalCrownRotation(..., sensitivity: .low, ...)` so larger physical crown turns are required before movement is detected.
- **Focus**: `WatchGameView` sets focus with `@FocusState` to keep crown input active during play.
- **Adapter**: Movement uses `CrownGameInputAdapter` to call `moveLeft()` / `moveRight()` on `GameScene`.

### Other Platforms (Summary)

- **iOS/iPadOS**: Touch areas + drag gestures (see `TouchGameInputAdapter`).
  - Touch-area taps use `onTapGesture` and horizontal swipes use a `DragGesture` threshold (`20pt`) for lane gestures.
  - VoiceOver Magic Tap maps to the same pause/resume toggle used by the in-game pause control.
- **tvOS**: Remote swipe input via `RemoteGameInputAdapter`.
- **macOS/visionOS**: Platform UI handles keyboard/mouse/gaze and forwards to shared controllers.
- **watchOS**: VoiceOver Magic Tap maps to the same pause/resume toggle used by the header pause control.

## User Experience

- **watchOS**: A single lane move per crown “turn,” matching the classic feel.
- **Accessibility**: Crown input remains focusable and works alongside VoiceOver.
- **Consistency**: Shared game logic remains deterministic and platform-agnostic.

## Testing Strategy

- Unit tests for the processor in `RetroRacingSharedTests/CrownInputProcessorTests.swift`.
- Watch UI should be verified manually to ensure the “one move per burst” feel.

## Known Issues

- Idle detection uses a debounce timer because SwiftUI lacks a direct crown idle callback.
- If the crown is rotated extremely slowly, the debounce window may need tuning.

## References

- [accessibility.md](accessibility.md)
- [testing.md](testing.md)
