# tvOS Parity

## Overview

This document describes the tvOS parity work that aligns tvOS with the shared UI and functionality used on iOS/macOS while respecting tvOS platform constraints.

## Scope

- Use the shared SwiftUI Menu/Game/Settings/Leaderboard views from `RetroRacingShared/Views/`.
- Centralize app bootstrap logic (Game Center access point, audio session, font registration) in shared code.
- Replace tvOS-unavailable sliders and compact picker presentations with focus-friendly selection screens.
- Keep tvOS-specific input handling in the UI layer via injected adapters and SwiftUI commands.

## Shared UI

The following views live in the shared module and are used by both iOS/macOS (Universal) and tvOS:

- `MenuView`
- `GameView`
- `SettingsView`
- `LeaderboardView`

### Style Injection

Shared views use injected style structs to keep a single code path while adjusting size/spacing for tvOS:

- `MenuViewStyle`
- `GameViewStyle`
- `SettingsViewStyle`

### Input Adapter Injection

`GameView` receives a `GameInputAdapterFactory` to keep platform input in the UI layer.

- iOS/macOS: `TouchInputAdapterFactory`
- tvOS: `RemoteInputAdapterFactory`

### tvOS Availability Guards

Shared SwiftUI views must avoid tvOS-unavailable APIs by using compile-time checks in the view layer (not services). This includes:

- `DragGesture` usage in shared overlays (disabled on tvOS)
- iOS-only navigation title display modifiers (guarded to iOS only)

## Settings (tvOS)

- Settings is one full-screen destination in the menu's single `NavigationStack`, not a modal sheet. Menu/Back leaves Settings or Tutorial without Done buttons; Back at the menu root is inert and never reveals the pre-game canvas.
- Settings uses a persistent sidebar/detail layout composed from system lists. The sidebar lists Game, Theme, Sound, Accessibility, Controls, Purchases, About, and Debug when available; selecting a row updates the detail column.
- Sidebar rows use the native rounded tvOS card focus treatment. Symbols occupy a consistent leading column with explicit spacing before the category title, including at larger text sizes. The selected category remains visibly marked while focus moves into its settings, and accessibility exposes that persistent state with the selected trait.
- Detail lists reserve focus-safe horizontal and vertical margins, give every custom card internal content padding plus breathing room between rows, and allow the focused lift/scale effect to render beyond the scroll viewport without clipping.
- Game contains Speed and Font. Speed uses dedicated Cruise, Fast, and Rapid rows with decorative gauges and a checkmark on the current value; this avoids compact picker contrast failures in dark appearance and keeps all game preferences on one page.
- Theme embeds the complete selectable Styles gallery in its category page; it does not push a gallery sub-screen. Every style is one native focus card containing its visible name, preview artwork, palette, and state glyph. The selected checkmark is sized for television viewing distance and uses the app accent color.
- Accessibility contains Big Cars, VoiceOver announcements for friend overtakes, and speed-increase warning feedback with a secondary native card-style preview action.
- Sound contains audio feedback, lane cue, tutorial, and volume controls only.
- The Sound Effects volume control uses a `Picker` with 5% steps (0% → 100%).
- Haptics section is hidden (tvOS has no haptics).
- Direct Touch is hidden because touch-based gameplay regions do not apply to Apple TV.
- Controls description uses `settings_controls_tvos` and documents swipe/click steering, Play/Pause, Menu/Back, and game controllers.
- Controller remaps are additive aliases. D-pad/stick, Menu/Start, and B/Back keep their native move, pause, and exit behavior.
- Disc is the free/default tvOS theme because the platform has not shipped yet. Debug builds expose a local feature-flag opt-out; disabling it updates the catalog immediately and restores the CRT catalog and default for comparison and QA.
- Builds without Debug UI ignore any persisted local override and retain the Disc platform default.
- Screenshot capture omits the Debug category even though the deterministic capture host uses a Debug build.

## Menu (tvOS)

- Uses shared `MenuView` with `MenuViewStyle.tvOS`.
- The menu is an app-owned opaque full-screen overlay and hides and disables the underlying game while presented, while leaving it mounted for controller monitoring.
- Tutorial and Settings are labeled, single-line television-scale actions in the top-right focus section; Tutorial appears immediately before Settings and neither action overlaps the centered game title.
- Moving Up from Play focuses Tutorial; moving Down from either Tutorial or Settings focuses Play.
- Play is the preferred initial focus. Returning from Tutorial or Settings restores focus to the action that opened the destination.
- Rate App button is hidden on tvOS.
- About always includes Rate RetroRapid!; on tvOS it opens the App Store product/rating surface because the direct written-review action is not supported there.
- Game Center auth receives one automatic attempt per menu instance. Dismissing the system sign-in UI must not present it again when the menu reappears; the leaderboard button remains disabled until authenticated.
- **Play with Friends** is always visible and bypasses the solo play-limit gate. It directly activates the shared Group Activity only when Apple reports an eligible FaceTime group; otherwise a localized alert explains that the player should start or join a FaceTime call. Incoming and continued sessions are observed for the app lifetime.

## Game (tvOS)

- Controller monitoring starts when `GameView` is mounted, including while the menu is covering the pre-game scene, so the first race accepts remote and game-controller input.
- Gameplay omits the Menu, Help, and Play/Pause toolbar buttons because the Siri Remote owns those actions. The shared HUD still presents the same three player/friend helmet strips and Hey Ho speed-warning artwork as iPhone and iPad; tvOS applies substantially larger score and helmet treatments with wider side rails for TV viewing distance. Consumed helmets remain visibly outlined and use higher residual opacity than handheld layouts.
- The speed-increase warning includes the shared Hey Ho artwork at a TV-distance scale and preserves its combined accessibility announcement.
- Friend milestone avatar pins use an injected expanded large-screen scale so they remain legible over upcoming cars from normal viewing distance without platform checks in the shared game engine.
- SharePlay waiting, countdown, friend-finish, and connection-loss overlays reuse the same first-party artwork as iPhone and iPad through explicit tvOS asset renditions, sized up for television viewing distance.
- The square gameplay canvas stays vertically centered inside the tvOS safe area, preserving comparable top and bottom margins.
- Remote left/right swipes and clickpad-edge taps use `onMoveCommand`.
- Play/Pause remote button uses `onPlayPauseCommand`.
- Menu/Back uses `onExitCommand` to pause and show a Finish Game / Keep Playing alert.
- Choosing Keep Playing restores focus to the game surface so later remote commands remain responsive.
- Keep Playing preserves an explicit user pause; Finish resets to a fresh pre-game session and returns to the menu.
- `RemoteInputAdapterFactory` drives left/right input via the shared `RemoteGameInputAdapter`.
- Game-over and achievement overlays use Large Title for their modal heading. Achievement headings precede the artwork; achievement names use Title 2 below the artwork, and the headings expose the accessibility header trait.
- Game-over, achievement, and SharePlay result actions stay in a fixed material footer while modal content scrolls above them. Two-action footers use equal-width horizontal controls, with Play Again or Restart using the filled system-pink prominent treatment and dismissive actions secondary; a single Done action remains prominent.

## Dynamic Type (tvOS)

- All settings and modal copy uses semantic app-font roles. On tvOS versions that expose user text-size controls, the sidebar widens at accessibility sizes and rows may wrap to two lines rather than truncate.
- tvOS 26 retains the same adaptive semantic layout even where the system does not expose the newer text-size setting.

## App Bootstrap

`AppBootstrap` (shared) provides:

- `configureGameCenterAccessPoint()`
- `configureAudioSession()`
- `registerCustomFont()`

Both Universal and tvOS apps call these at startup.

## Testing

Unit tests cover the mounted pre-game controller-listener lifecycle, platform presentation styles, vertical safe-area policy, category visibility, App Store rating destinations, HUD scaling, and shared SharePlay state transitions. tvOS UI-test launches suppress live Game Center authentication presentation so focus/navigation assertions are deterministic. tvOS UI tests cover Play, left/right remote commands, Play/Pause pause and resume, both outcomes of the Menu/Back finish-game alert, bounded Tutorial/Settings navigation, settings sidebar selection and detail updates, changing the inline Game speed in dark appearance, the embedded Theme gallery, Accessibility controls, the About rating entry point, menu-root Back behavior, utility-action placement, and menu focus restoration. Manual device QA covers light and dark appearance, focus clipping, large text on tvOS 27, normal viewing-distance HUD readability, the App Store handoff, FaceTime eligibility guidance, and incoming/continued SharePlay sessions.

After changes:

```bash
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingSharedTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingUniversalTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingTvOS -destination "platform=tvOS Simulator,name=Apple TV 4K (3rd generation),OS=latest" -only-testing:RetroRacingTvOSUITests
```

## Notes

- No service-layer `#if os()` usage was added.
- View-level platform differences remain isolated to injected style and input factories.
