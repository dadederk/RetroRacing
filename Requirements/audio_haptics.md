# Audio & Haptics Requirements (2026-02-15)

## Goals
- Consistent pulse feedback:
  - `Retro audio` mode:
    - Grid tick plays an arpeggio using the three-lane safe pattern.
    - Left/right move plays a distinct lane-confirmation pulse using the middle-lane timbre.
    - Light impact haptic still fires on every left/right move and every grid tick.
  - Cue modes (`chord`, `arpeggio`, `lane pulses`): replace `bip` with generated lane cues; haptic behavior remains unchanged.
- Crash feedback: play `fail` sound and trigger error haptic immediately on collision; crash sprite flashes while the sound plays.
- Safe start: game remains paused while `start` sound plays (initial launch and post-crash resume), then unpauses automatically at completion.
- Exiting the game stops any playing sounds with a very short fade-out.
- User control: single master SFX volume slider (0–100%, default 80%), audio feedback mode selector, and lane-change cue style selector (`lane confirmation`, `success`, `lane + success`) in Settings on all platforms.

## Implementation Rules
- Shared audio abstraction `SoundEffectPlayer`; injected into `GameScene` (no defaults in initializers).
- Primary runtime SFX path uses `AVGeneratedSoundEffectPlayer` (generated PCM for `start`, `bip`, `fail`) with a modular `GeneratedSFXProfile`/recipe model.
- Generated SFX recipes are composed from ordered segments (`intro`, `body`, optional repeated `tailPattern`) so tuning is code-only constant edits.
- `GeneratedSFXProfile.failTailRepeatCount` is the one-line fail-tail repetition knob; default is baseline minus one repeat to shorten fail feedback.
- Fallback runtime path uses `FallbackSoundEffectPlayer` + bundled-asset `AVSoundEffectPlayer` for resilience when generated playback is unavailable.
- Shared cue abstraction `LaneCuePlayer` with AVFoundation implementation `AVLaneCuePlayer`; injected into `GameScene` and backed by generated PCM buffers (no prerecorded cue assets required).
- Sound IDs remain `start`, `bip`, `fail`; `.m4a` assets remain in the shared bundle as fallback only.
- Generated + asset players both use a small `bip` pool so rapid tick/move pulses do not restart and get dropped.
- `GameScene` uses `SoundEffectPlayer` for start/fail. Tick/move guidance uses `LaneCuePlayer` in cue modes and also in retro mode for distinct tick/move timbres.
- Cue mode behavior:
  - Tick cue: announce currently safe columns in the row directly ahead of the player.
  - Move cue style:
    - `Lane confirmation`: destination lane only.
    - `Success`: safe/unsafe indicator only.
    - `Lane + success`: destination lane followed by safe/unsafe indicator as two quick notes.
  - Retro mode uses:
    - Tick: `playTickCue` with all three columns and `cueArpeggio` mode.
    - Move: `playMoveCue` with middle-lane lane-confirmation tone.
- `stopAll(fadeDuration: 0.1–0.2s)` is exposed and called when leaving the game view, forwarding to both audio systems.
- Move haptics are triggered by touch/remote input adapters immediately when left/right input is handled, before forwarding to `GameScene`.
- Crash haptic is triggered in `handleCrash` immediately; collision resolution completes on fail-sound completion with an 8s fallback if completion is missing (e.g. route change), so normal flow waits for the active fail cue to finish.
- Start/resume keeps `gameState.isPaused == true` until `start` sound completion sets it to false; on post-crash resume the player-car grid is rendered immediately (no lingering crash sprite), and a 2s fallback unpauses if completion is missing.
- App bootstrap listens to audio session interruption/route/media-reset notifications and re-activates the session.
- Volume persists via `UserDefaults` key `sfxVolume` (default `0.8`); settings slider writes this, and scenes update volume live.
- Audio feedback mode persists via `ConditionalDefault<AudioFeedbackMode>` (`audioFeedbackMode_conditionalDefault`): VoiceOver-adaptive default (`arpeggio`) with explicit user override.
- Lane move cue style persists via `UserDefaults` key `laneMoveCueStyle` (default `lane confirmation`).
- In-game/tutorial preview playback uses `LaneCuePlayer` with the current SFX volume, supports lane-mode preview and safe/fail move-style preview, and must call `stopAll` on dismiss so previews never leak into gameplay.
- Haptics respect existing toggle (`hapticFeedbackEnabled`); no changes to keys.

## Testing Expectations
- Unit tests cover: generated-player completion/volume/stop behavior; recipe modularity (including fail-tail repeat count impact); fallback routing to asset player when generated playback is unavailable; retro tick arpeggio + retro move middle-lane routing; cue-mode routing for tick and move cues; lane move cue style forwarding; paused move input still triggers adapter haptic while movement audio remains unchanged; fail sound + crash haptic on collision; crash fallback fires once when completion is missing; start/resume pauses until sound completion with fallback and restores player visuals immediately after crash; stopAll invoked when game view disappears; volume changes propagate to both `SoundEffectPlayer` and `LaneCuePlayer`; conditional default/override resolution for audio feedback mode.
