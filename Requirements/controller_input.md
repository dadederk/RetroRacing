# Controller Input

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Physical game controller support via GameController on iOS, iPadOS, macOS, and tvOS, including remappable bindings.
- **Must not break:** tvOS directional/pause input stays routed through Siri Remote commands; remaps persist globally; `GameControllerInputSource` is injected at composition roots.
- **Key files:** `GameControllerInputSource`, `SystemGameControllerInputSource`, `GameControllerBindingProfile`, `GameControllerActionRouter`, `GameView`, `SettingsView`.

## Platform Behavior

| Platform | Directional input | Pause |
|---|---|---|
| iOS / iPadOS / macOS | D-pad and left stick | Start/Menu button |
| tvOS | `.onMoveCommand` | `.onPlayPauseCommand` |

- tvOS does not capture controller directional/menu input to avoid double-triggering with Siri Remote behavior.
- watchOS is out of scope. visionOS remains stubbed until planned.

## Remapping

- Settings lets players remap Move Left, Move Right, and Pause/Resume.
- Supported remap buttons: A, B, X, Y, left/right shoulder, left/right trigger, Menu, or none where supported by the model.
- One button maps to one action. Assigning a used button clears the previous action.
- One global binding profile applies to all connected controllers.
- Left stick remains a directional backup on iOS/iPadOS/macOS even when D-pad/menu actions are remapped.
- Bindings are stored as JSON under `gameControllerBindingProfile`; corrupt or missing data falls back to defaults.

## Input Source Contract

- `GameControllerInputSource.start(handler:)` begins observation and emits `GameControllerAction` on the main actor.
- `stop()` detaches handlers and clears per-controller stick state.
- `SystemGameControllerInputSource` observes connect/disconnect notifications and reads the current binding from UserDefaults on every press so Settings changes apply immediately.
- Stick hysteresis prevents repeated lane moves while held: trigger at +/-0.5, reset inside +/-0.2.

## Routing

`GameControllerActionRouter` is pure:

| Action | Menu hidden | Menu visible |
|---|---|---|
| Move left/right | lane move | ignored |
| Pause/resume | toggle pause | request Play |

- Routed controller play requests use the same session-aware play path as menu Play.
- Every routed gameplay action records `AchievementControlInput.gameController` for the completed run.

## Settings and Localization

- Controls settings expose a “How to play the game” row, then controller mapping on supported shared surfaces.
- macOS uses a scroll layout for reliable settings-window rendering.
- Controller labels and footer copy live in the shared string catalog.

## Testing

- Unit tests cover binding defaults, conflict resolution, persistence fallback, router combinations, and immediate remap behavior.
- Manual hardware validation covers iOS/iPadOS, macOS, and tvOS controllers, including adaptive/Xbox/PlayStation-style devices where available.
