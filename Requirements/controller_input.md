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
| tvOS | `.onMoveCommand` from D-pad and left stick | `.onPlayPauseCommand` from Start/Menu |

- tvOS uses `onExitCommand` for controller B/Back and Siri Remote Menu/Back; during an active race it opens a finish confirmation.
- tvOS does not directly capture controller D-pad, stick, Menu/Start, or B/Back input, avoiding duplicate events with the focus command system.
- watchOS is out of scope. visionOS uses the standard controller source for lane movement and pause/resume.

## Remapping

- Settings lets players remap Move Left, Move Right, and Pause/Resume.
- Supported remap buttons: A, B, X, Y, left/right shoulder, left/right trigger, Menu, or none where supported by the model.
- One button maps to one action. Assigning a used button clears the previous action.
- One global binding profile applies to all connected controllers.
- Left stick remains a directional backup on iOS/iPadOS/macOS even when D-pad/menu actions are remapped.
- On tvOS, standard D-pad/stick and Menu/Start controls always remain active. A, X, Y, shoulder, and trigger mappings are additive aliases; B/Back remains reserved for exit.
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
- tvOS copy documents Siri Remote swipe/click, Play/Pause, Menu/Back, standard controller controls, and additive aliases.
- macOS uses a scroll layout for reliable settings-window rendering.
- Controller labels and footer copy live in the shared string catalog.

## Testing

- Unit tests cover binding defaults, conflict resolution, persistence fallback, router combinations, and immediate remap behavior.
- Manual hardware validation covers iOS/iPadOS, macOS, and tvOS controllers, including adaptive/Xbox/PlayStation-style devices where available.
