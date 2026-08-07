# Accessibility

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Cross-platform accessibility behavior: Reduce Motion, VoiceOver, Direct Touch, Voice Control, Dynamic Type, conditional defaults, pause/help flows, and accessible game-over/SharePlay UI.
- **Must not break:** Reduce Motion replaces crash blink with fade; interactive UI is labeled; gameplay exposes meaningful status/controls; conditional defaults honor system state until the user overrides.
- **Key files:** `GameScene+Effects`, `AccessibilityNotification`, `ConditionalDefault`, `VoiceOverStatus`, `SettingsView`, `GameView`, `GameOverView`, `SharePlayOverlayView`.

## Reduce Motion and Contrast

- Crash blink animation becomes a fade when Reduce Motion is enabled.
- Decorative motion should be removed or simplified when system Reduce Motion is active.
- Gameplay feedback must remain available through non-motion channels.
- Themes, HUD, road markers, cars, and overlays must remain readable with increased contrast needs; see [theming_system.md](theming_system.md) and [road_markers.md](road_markers.md).

## VoiceOver Gameplay

- The Classic solo HUD shows the score as a numeric value without a visible prefix and shows
  three helmet icons for lives. Consumed helmets fade in order from left to right and keep a
  primary-contrast outline while the remaining helmets stay fully visible. The spatial
  attached HUD uses an explicit localized score/lives/level text line so status does not
  depend on resolving small sprite details at a distance.
- SharePlay presents the same three-helmet lives model for the friend. Friend helmets are
  decorative within the row's combined score/lives accessibility element and are not announced
  individually.
- Score and lives remain exposed as read-only status with localized labels; the frequently
  updating score must not interrupt VoiceOver gameplay.
- Score rolling motion and helmet fade animation are disabled when Reduce Motion is enabled.
- Active gameplay exposes left/right direct-touch regions and hides non-interactive SpriteKit grid content from VoiceOver.
- Explicit user pause switches to a row-major grid exploration overlay with occupant and coordinate labels.
- Implicit pauses (crash/start/help/menu/overlay) must not switch to grid exploration or cause disruptive focus jumps.
- VoiceOver Magic Tap follows the same pause/resume path as the toolbar button.
- First active VoiceOver gameplay session auto-presents in-game help once per device profile.

## Controls and Voice Control

- Direct Touch defaults to on where shown and persists user overrides. It is hidden on tvOS, where touch-based gameplay regions do not apply.
- On visionOS, Direct Touch applies only to the Classic board and spatial road; the attached native HUD, placement guidance, Settings, and native controls keep standard assistive navigation.
- Voice Control input labels include short and descriptive aliases: Left/Move left and Right/Move right.
- HUD status and SpriteKit visuals are not Voice Control tap targets.
- Settings Style Gallery rows are semantic buttons with localized theme descriptions. The currently selected style exposes the selected accessibility trait in addition to its visual checkmark.
- tvOS maps Siri Remote directional input through `onMoveCommand`.
- macOS disables gameplay trackpad lane swipes while VoiceOver is running.

## Audio, Haptics, and Warnings

- Audio feedback modes: Retro audio, lane pulses, arpeggio, chord.
- Cue modes announce safe columns each grid tick.
- Move cue style supports lane confirmation, success, lane + success, or haptics where available.
- Speed warning feedback supports VoiceOver announcement, haptic, sound, or none, with haptics options hidden on unsupported platforms.
- Speed warning announcement mode uses high-priority accessibility announcements.
- In-game help includes previews/guidance for controls, audio cues, and speed warnings.

## Conditional Defaults

- Conditional settings resolve from system/accessibility state until a user override is stored.
- `ConditionalDefault<Value>` stores either system-default mode or explicit override.
- Current conditional defaults include:
  - Difficulty: Cruise when VoiceOver is running, Rapid otherwise.
  - Audio feedback: lane pulses with VoiceOver, Retro audio otherwise.
  - Sound effects volume: 100% with VoiceOver, 80% otherwise.
  - Speed warning: haptic or announcement with VoiceOver depending on platform, none otherwise.
  - Big Cars: on for accessibility Dynamic Type sizes, off otherwise.
  - Direct Touch: on where the setting is shown.
  - Road visual style: Detailed Road unless overridden; Big Cars forces vertical-only rendering.

## Dynamic Type and Layout

- Shared UI uses semantic font APIs so system and retro font modes scale with Dynamic Type.
- The universal gameplay score uses Title 3; the SharePlay friend's score uses Headline. Helmet
  icons scale relative to their adjacent semantic text style at every Dynamic Type size. Both
  player and friend helmets compensate for their normalized safety inset so their visible artwork,
  rather than a square fit or the full transparent canvas, matches the corresponding score height.
- The SharePlay friend row reflows its score and right-aligned helmet strip at accessibility sizes
  when the horizontal presentation would clip.
- Menu, Settings, game-over, achievement, and paywall content must scroll or reflow rather than clip at large sizes.
- Portrait gameplay stacks HUD above the game and controls below to avoid overlap.
- Regular-width compact-height layouts may use side rails; regular-regular and compact-width layouts keep a full-width top HUD.
- Social rows stack avatar/text at accessibility sizes when needed.

## Game-Over, Achievements, and Sharing

- Game-over sheets are not interactively dismissible; Restart/Finish are explicit.
- Decorative artwork and icons are hidden from accessibility when equivalent text exists.
- Summary rows and social recaps are exposed in logical scroll order.
- Achievement unlock sheets present above game over and include explicit Done plus Game Center link where supported.
- Share actions use semantic labels and export content-only images without action chrome.

## SharePlay Accessibility

- SharePlay overlays are single combined accessibility elements with art/icon, title, and subtitle.
- Countdown cards keep stable labels and do not post per-second VoiceOver announcements.
- SharePlay HUD uses concise You/Friend score rows and three friend helmets without “overtakes”
  copy. The friend row remains one combined score/lives accessibility element.
- SharePlay result sheets are explicitly dismissed through Play Again, Leave, or Done.
- Speed settings are disabled, not hidden, while SharePlay is active; see [shareplay_multiplayer.md](shareplay_multiplayer.md).
- visionOS exposes the shared waiting, countdown, live-score, disconnect, and result semantics in Classic presentation. If a session arrives in spatial mode, gameplay pause-locks before the automatic Classic handoff so assistive input cannot advance an unseen round.

## Navigation

- Gameplay disables interactive pop gestures where horizontal swipes control the car.
- Full-screen menu overlays are Play-only dismiss and pause gameplay underneath.
- macOS menu overlay is modal and hides underlying gameplay from the accessibility tree.
- watchOS Finish returns to the menu and stops gameplay, haptics, and pending audio callbacks.
- visionOS exposes HUD state and controls through SwiftUI in both Classic and spatial mode. The high-contrast attached HUD presents score, the shared three-helmet lives strip, level, pause, and presentation actions beyond the far road edge and reflows for large Dynamic Type. Spatial action buttons use a cyan accent, switching to yellow with Increase Contrast, with dark prominent-action labels so text and symbols never blend into their button backgrounds.
- Spatial mode preserves the run during placement and handoff and provides full-road semantic lane targets, named movement actions, and an adjustable lane action without requiring 3D exploration or visible movement buttons.
- Placement/search/recovery messages expose localized status and instructions. Focus restores to Resume in 3D after anchoring, the current lane after confirmation, or recovery guidance after anchor loss/failure.
- visionOS road, lane, car, and collision state remains distinguishable with Reduce Motion, Reduce Transparency, Increase Contrast, and Differentiate Without Color enabled. The dual-car collision pose never blinks with Reduce Motion and uses raised multi-part geometry rather than color alone.

## Testing

- Unit tests cover conditional defaults, settings migrations, audio/warning routing, direct touch persistence, paused-grid descriptors, VoiceOver/Voice Control scope, Dynamic Type layout guards, and SharePlay accessible state.
- Manual QA covers VoiceOver, Switch Control, Voice Control, Dynamic Type, Reduce Motion, keyboard/controller/remote/crown input, game-over/achievement sheets, and SharePlay overlays on supported platforms.
