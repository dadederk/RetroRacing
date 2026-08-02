# Audio and Haptics

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Generated SFX, lane cue modes, haptics, start/fail/crash feedback, SharePlay countdown cues, Settings selectors, and audio-session recovery.
- **Must not break:** `SoundEffectPlayer` and `LaneCuePlayer` are injected; gameplay stays paused during start sound; fail-open audio never stalls gameplay; platform option availability matches capabilities.
- **Key files:** `AVGeneratedSoundEffectPlayer`, `AVLaneCuePlayer`, `GameScene` audio hooks, Settings audio preferences.

## Feedback Modes

- Retro audio: generated tick/move/start/fail sounds with haptic movement/tick feedback.
- Audio cue modes: lane pulses, arpeggio, and chord; tick cues announce safe columns.
- Lane move cue styles: lane confirmation, success, lane + success, haptics.
- Speed warning feedback: VoiceOver announcement, haptic, sound, none.
- Haptics options are hidden on unsupported platforms.

## Runtime Contract

- Start/resume keeps gameplay paused until start sound completion or fallback timeout.
- Crash immediately triggers fail sound and error haptic; collision resolution continues on completion or fallback timeout.
- Exiting gameplay stops generated SFX and lane cues with a short fade/stop.
- Generated audio is PCM rendered at runtime; no prerecorded cue assets are required.
- Lane guidance never falls back to generic `bip`; if cues are unavailable, cue feedback is skipped and haptics still follow policy.
- SharePlay countdown uses generated 3/2/1/go cues and must not replay the normal solo start cue.

## Fail-Open and Session Recovery

- Audio engine/player startup failures are recoverable.
- Playback preflights must skip unsafe `AVAudioPlayerNode.play()` calls when the app, session, engine, node, or formats are not ready.
- Skipped playback still calls completion asynchronously on the main queue where gameplay is waiting.
- Audio graph lifecycle events mark players dirty and rebuild lazily on next playback.
- Audio mutations are serialized on the main thread to avoid fade/schedule races.

## Preferences

- SFX volume uses `ConditionalDefault<SoundEffectsVolumeSetting>`: 100% with VoiceOver, 80% otherwise.
- Audio feedback mode uses a VoiceOver-adaptive conditional default: lane pulses with VoiceOver, Retro otherwise.
- Speed warning uses a VoiceOver/platform-aware conditional default and migrates legacy announcement settings once.
- Lane move cue style persists with `laneMoveCueStyle`.
- Tutorial/settings previews must stop on dismiss and must not leak into gameplay.

## Platform Notes

- watchOS activates and re-activates its audio session on app start, gameplay appear, foregrounding, route/interruption/media reset, and live-menu exit.
- watchOS haptic timing should align with actual lane changes and native semantic patterns.
- macOS and tvOS do not expose haptics-only options.
- Temporary Xcode 26 archive behavior uses the legacy audio activation path; see [../Docs/xcode-27-sdk-restore.md](../Docs/xcode-27-sdk-restore.md).

## Testing

- Unit tests cover generated recipe durations, fail-open completions, start/fail fallback, volume propagation, cue routing, haptic lane style, SharePlay countdown scheduler, preference defaults/migrations, preview stop, and gameplay-session teardown.
