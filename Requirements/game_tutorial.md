# In-Game Tutorial Requirements

## Overview

RetroRacing provides in-game help so players can learn controls and audio cues without leaving gameplay. The tutorial is available manually from gameplay and conditionally from Settings when cue-based audio is selected.

## Entry Points

- Gameplay toolbar includes a `?` help button on shared platforms and watchOS.
- Tapping `?` opens a help modal with:
  - Controls guidance (same platform-specific controls copy used in Settings).
  - Audio cue tutorial with interactive previews.
- Settings shows an **Audio cue tutorial** row only when audio feedback mode is not `Retro audio`.

## VoiceOver First-Run Behavior

- If VoiceOver is running and the user has not seen the tutorial before, gameplay auto-presents the help modal once.
- Auto-presentation is persisted with `VoiceOverTutorialPreference.hasSeenInGameVoiceOverTutorialKey`.
- Auto-presentation is independent of selected audio mode.
- Auto-presentation only triggers after gameplay is active (scene exists and is not currently paused).

## Pause Semantics

### Manual help (`?`)

- Opening help pauses gameplay while the modal is visible.
- Dismissing help restores the exact previous pause state:
  - If gameplay was running, it resumes.
  - If gameplay was already paused (including user pause), it remains paused.

### Auto VoiceOver help

- Opening help pauses gameplay only if gameplay was running.
- Dismissing help resumes only when the tutorial introduced that pause.

## Audio Tutorial Content

The audio tutorial explains and previews:

- Lane cue modes:
  - `Audio cues (arpeggio)`
  - `Audio cues (lane pulses)`
  - `Audio cues (chord)`
- Lane change cue styles:
  - `Lane confirmation`
  - `Success`
  - `Lane + success`
- Move style previews include both **Safe** and **Fail** actions.

## Technical Notes

- VoiceOver status is accessed through shared helper `VoiceOverStatus`.
- Auto-show decision logic uses `InGameHelpPresentationPolicy`.
- Preview playback uses shared `LaneCuePlayer` and current SFX volume.
- Preview playback is additive and does not alter runtime gameplay routing.

## Testing Expectations

- Unit tests cover:
  - Auto-show policy decisions.
  - Manual help pause restore behavior.
  - Settings/tutorial visibility logic (`retro` vs cue modes).
  - Audio preview routing and stop behavior.
- Existing audio and pause regression tests remain green.
