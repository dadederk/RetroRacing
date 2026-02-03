# Audio & Haptics Requirements (2026-02-03)

## Goals
- Consistent pulse feedback: play `bip` + light impact haptic on every left/right move and every grid tick.
- Crash feedback: play `fail` sound and trigger error haptic immediately on collision; crash sprite flashes while the sound plays.
- Safe start: game remains paused while `start` sound plays (initial launch and post-crash resume), then unpauses automatically at completion.
- Exiting the game stops any playing sounds with a very short fade-out.
- User control: single master SFX volume slider (0–100%, default 80%) in Settings on all platforms.

## Implementation Rules
- Shared audio abstraction `SoundEffectPlayer` with AVFoundation implementation `AVSoundEffectPlayer`; injected into `GameScene` (no defaults in initializers).
- Sound IDs: `start`, `bip`, `fail` (all `.m4a` in shared bundle).
- `GameScene` uses `SoundEffectPlayer` for all playback; `stopAll(fadeDuration: 0.1–0.2s)` is exposed and called when leaving the game view.
- `GameScene` fires `gameSceneDidUpdateGrid` for both ticks and user moves so haptics run everywhere; crash haptic is triggered in `handleCrash` immediately.
- Start/resume keeps `gameState.isPaused == true` until `start` sound completion sets it to false.
- Volume persists via `UserDefaults` key `sfxVolume` (default `0.8`); settings slider writes this, and scenes update volume live.
- Haptics respect existing toggle (`hapticFeedbackEnabled`); no changes to keys.

## Testing Expectations
- Unit tests cover: bip on move and tick; fail sound + crash haptic on collision; start/resume pauses until sound completion; stopAll invoked when game view disappears; volume changes propagate to `SoundEffectPlayer`.
