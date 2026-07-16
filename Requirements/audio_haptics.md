# Audio & Haptics Requirements (2026-02-25)

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** SFX modes (retro vs lane cues), haptics, start/fail/crash feedback, and Settings selectors.
- **Must not break:** Injected `SoundEffectPlayer`/`LaneCuePlayer` (no init defaults); game paused during start sound; cross-platform semantic parity for audio events.
- **Key files:** `AVGeneratedSoundEffectPlayer`, `AVLaneCuePlayer`, `GameScene` audio hooks.

## Goals
- Consistent pulse feedback:
  - `Retro audio` mode:
    - Grid tick plays an arpeggio using the three-lane safe pattern.
    - Left/right move plays a distinct lane-confirmation pulse using the middle-lane timbre.
    - Light impact haptic still fires on every left/right move and every grid tick.
  - Cue modes (`chord`, `arpeggio`, `lane pulses`): replace `bip` with generated lane cues.
- Crash feedback: play `fail` sound and trigger error haptic immediately on collision; crash sprite flashes while the sound plays.
- Safe start: game remains paused while `start` sound plays (initial launch and post-crash resume), then unpauses automatically at completion.
- Exiting the game stops any playing sounds with a very short fade-out.
- Cross-platform parity policy: iPhone/watchOS and other targets keep independent local settings (no cross-device sync), but audio-related option availability and event-to-sound semantics stay aligned where platform capabilities allow.
- User control in Settings:
  - SFX volume slider (0–100%).
  - Audio feedback mode selector (display order: `Retro`, `Audio cues (lane pulses)`, `Audio cues (arpeggio)`, `Audio cues (chord)`).
  - Lane-change cue style selector (`Lane confirmation`, `Success`, `Lane + success`, `Haptics`).
  - Speed increase warning feedback selector (`VoiceOver announcement`, `Haptic`, `Sound`, `None`).

## Implementation Rules
- Shared audio abstraction `SoundEffectPlayer`; injected into `GameScene` (no defaults in initializers).
- Primary runtime SFX path uses `AVGeneratedSoundEffectPlayer` (generated PCM for `start`, `bip`, `fail`) with a modular `GeneratedSFXProfile` built on the shared pure `ArcadeAudioKit` recipe/rendering package.
- Generated SFX recipes are composed from ordered `ArcadeAudioKit` segments (`intro`, `body`, optional repeated `tailPattern`) so tuning is code-only constant edits while AVFoundation playback remains RetroRapid-owned.
- `GeneratedSFXProfile.failTailRepeatCount` is the one-line fail-tail repetition knob; default is baseline minus one repeat to shorten fail feedback.
- Shared cue abstraction `LaneCuePlayer` with AVFoundation implementation `AVLaneCuePlayer`; injected into `GameScene` and backed by generated PCM buffers (no prerecorded cue assets required).
- Sound IDs remain `start`, `bip`, `fail`; all three effects are generated at runtime.
- Generated SFX uses a small `bip` pool so rapid tick/move pulses do not restart and get dropped.
- `GameScene` uses `SoundEffectPlayer` for start/fail. Tick/move guidance uses `LaneCuePlayer` in cue modes and also in retro mode for distinct tick/move timbres.
- Lane-guidance semantics never fall back to `bip`; if lane cues are unavailable, tick/move guidance cues are skipped and move keeps haptic feedback only.
- Cue mode behavior:
  - Tick cue: announce currently safe columns in the row directly ahead of the player.
  - Move cue style:
    - `Lane confirmation`: destination lane only.
    - `Success`: safe/unsafe indicator only.
    - `Lane + success`: destination lane followed by safe/unsafe indicator as two quick notes.
    - `Haptics`: no lane audio move cue; trigger success haptic for safe destination and regular move haptic for unsafe destination.
- Move haptics:
  - Default path: triggered by touch/remote/crown adapters immediately when left/right input is handled.
  - Exception: when cue mode is active and lane style is `Haptics`, adapters suppress immediate move haptic and `GameScene` emits safe/unsafe-specific haptic.
- watchOS crown input refines move-haptic timing: default move haptic fires only when a crown action actually changes lane (no haptic on boundary no-op turns).
- watchOS Settings volume control uses `ViewThatFits` with an inline slider+labels layout for wide widths and a stacked slider+label-row fallback for narrower widths.
- Crash haptic is triggered in `handleCrash` immediately; collision resolution completes on fail-sound completion with an 8s fallback if completion is missing.
- Start/resume keeps `gameState.isPaused == true` until `start` sound completion sets it to false; on post-crash resume the player-car grid is rendered immediately (no lingering crash sprite), and a 2s fallback unpauses if completion is missing.
- App bootstrap listens to audio session interruption/route/media-reset notifications and re-activates the session.
- Audio-session activation is nonblocking: use `AVAudioSession.activate(options:completionHandler:)` on iOS/tvOS/visionOS 27+ where the compile SDK allows it, with a detached `setActive(true)` fallback for older OS/SDK toolchains. **Temporary:** Xcode 26 archives use the legacy path only — see [Docs/xcode-27-sdk-restore.md](../Docs/xcode-27-sdk-restore.md).
- watchOS also configures and activates an AVAudioSession at app startup so generated SFX/lane cues have an active playback session.
- watchOS gameplay re-activates the audio session on `WatchGameView` appear before starting the scene, so returning from overlays/menu restores sound output reliably.
- watchOS gameplay also re-activates the audio session when scene phase returns to `active` so post-interruption foregrounding restores sound without requiring a relaunch.
- watchOS live-menu exit ends the active gameplay session before dismissing the game view: the scene is pause-locked, SpriteKit updates are paused, pending start/crash callbacks are cancelled, and all generated SFX/lane cues are stopped immediately so haptics/audio cannot continue behind the menu.
- watchOS audio session uses `.playback` without mix options to prioritize in-app SFX audibility.
- watchOS audio-session lifecycle now observes interruption/route/media-reset notifications and re-activates the session in all three cases.
- Generated SFX engine start failures are treated as recoverable; transient startup failures no longer permanently disable subsequent SFX playback attempts.
- `AVGeneratedSoundEffectPlayer` and `AVLaneCuePlayer` now require a live engine preflight immediately before node playback; when preflight fails, playback is skipped instead of calling `AVAudioPlayerNode.play()` in an unsafe state.
- `AVGeneratedSoundEffectPlayer` fail-open rule: when playback is skipped, completion callbacks still execute asynchronously on the main queue so gameplay flows (start-unpause / crash resolution) do not stall.
- Player-node startup now has a final readiness gate immediately after scheduling and before `AVAudioPlayerNode.play()`: iOS-family playback is skipped unless the app is active, the audio session can be activated, the engine is running, the node is still attached, and output/mixer/player formats expose playable sample rate and channels.
- Generated SFX completion callbacks always hop asynchronously to the next main-queue turn before invoking gameplay completion handlers, preventing crash recovery from starting the next sound from inside the previous sound graph callback.
- Both generated-SFX and lane-cue players observe audio-session lifecycle events (interruption end, route change, media-services reset) plus `AVAudioEngineConfigurationChange`; they mark the audio graph dirty and lazily rebuild/restart on the next playback request.
- Audio-player state mutations (play/schedule/stop/volume/fade) are serialized onto the main thread to avoid races between fade tasks and playback scheduling.
- Audio playback internals are decomposed into focused shared helpers (`GeneratedSFXPlaybackGraph`, `LaneCuePlaybackGraph`, `LaneCueBufferFactory`) so player types remain orchestration-focused while preserving fail-open behavior.
- SFX volume persistence uses `ConditionalDefault<SoundEffectsVolumeSetting>` (`sfxVolume_conditionalDefault`):
  - VoiceOver ON system default: `1.0`
  - VoiceOver OFF system default: `0.8`
  - User slider changes store explicit override and always win after migration.
- Speed warning feedback persistence uses `ConditionalDefault<SpeedWarningFeedbackMode>` (`speedWarningFeedbackMode_conditionalDefault`) resolved through `SpeedWarningFeedbackPreference`:
  - VoiceOver OFF default: `none`
  - VoiceOver ON + haptics supported default: `warningHaptic`
  - VoiceOver ON + haptics unsupported default: `announcement`
  - User override always wins.
- Migration (`SettingsPreferenceMigration`):
  - Legacy `inGameAnnouncementsEnabled == true` -> keep system default (no migrated override)
  - Legacy `false` -> `none` (explicit migrated override)
  - Legacy `sfxVolume` seeds conditional default override
  - Runs once via migration marker key.
- Audio feedback mode persists via `ConditionalDefault<AudioFeedbackMode>` (`audioFeedbackMode_conditionalDefault`): VoiceOver-adaptive default is `lane pulses` on all platforms (including watchOS via shared `VoiceOverStatus`), otherwise `retro`.
- Lane move cue style persists via `UserDefaults` key `laneMoveCueStyle`.
- In-game/tutorial preview playback uses `LaneCuePlayer` with the current SFX volume and must call `stopAll` on dismiss so previews never leak into gameplay.
- Settings and tutorial include `Preview warning` for speed increase warning feedback; preview behavior matches gameplay for all four modes.
- Tutorial apply actions for audio mode, lane cue style, and speed increase warning feedback switch to a disabled `X configured` state when preview selection already matches the stored setting.
- Settings + watch Settings hide the `Audio cue tutorial` entry when selected audio mode is `Retro audio`.
- In-game help hides audio-cue tutorial sections when selected audio mode is `Retro audio` and only shows speed-warning tutorial content when the configured speed-warning mode is not `None`.
- Settings disable `Preview warning` when mode is `None`, and also when mode is `VoiceOver announcement` while VoiceOver is currently off.
- Haptics respect existing toggle (`hapticFeedbackEnabled`).
- Platform policy:
  - macOS and tvOS do not expose haptics options.
  - Lane style `Haptics` option is filtered out where haptics are unsupported.
  - Speed increase warning feedback uses `AccessibilityNotification.Announcement` for announcement mode on all platforms.
  - Speed increase warning announcement mode posts with high announcement priority.
  - Speed increase warning `Haptic` mode triggers two consecutive warning haptic events.
  - watchOS tick/move/crash/success haptics are dispatched immediately on the main thread to keep feedback aligned with gameplay timing.
  - watchOS warning haptics keep a short internal spacing so the two warning pulses remain distinct.
  - watchOS mirrors iOS haptic intent semantics using native system patterns: tick maps to light-impact equivalent (`click`), move-complete maps to medium-impact equivalent (`start`), and crash/success/warning keep failure/success/notification semantics.
  - Speed increase warning sound uses a dedicated generated cue (`D4-F4-A4`, repeated twice) and does not reuse lane-safe tick cues.

## Testing Expectations
- Unit tests cover: generated-player completion/volume/stop behavior; generated-player fail-open completion when final player-start readiness fails; recipe modularity (including fail-tail repeat count impact); retro tick arpeggio + retro move middle-lane routing; cue-mode routing for tick and move cues; lane move cue style forwarding (including `Haptics` safe/unsafe behavior); lane-cue fail-open grid progression when final player-start readiness fails; paused move input behavior; fail sound + crash haptic on collision; crash fallback fires once when completion is missing; start/resume pauses until sound completion with fallback and restores player visuals immediately after crash; gameplay-session end stops updates, stops audio, and cancels pending crash callbacks; stopAll invoked when game view disappears; volume changes propagate to both `SoundEffectPlayer` and `LaneCuePlayer`; conditional-default/override resolution and migration for audio/speed warning settings.
