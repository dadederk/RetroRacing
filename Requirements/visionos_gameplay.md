# visionOS Gameplay

## Overview

The visionOS app presents one solo RetroRapid! run as either a Classic SwiftUI window or a gravity-aligned RealityKit volume. Both renderers consume the same shared `GameEngine` snapshots; changing presentation never creates or advances a second run.

The 3D scene is a pushed volumetric `WindowGroup`, not an immersive space. visionOS keeps the volume where the user places it, provides movement through the system window bar, and can snap its bottom to a horizontal surface. Surface snapping is optional: the game remains playable while floating and requests no world-sensing permission or custom placement gesture.

## Launch and Session

- The app opens in Classic on the shared universal-style menu and does not advance gameplay before Play.
- Scene restoration is disabled for both presentations: launch deterministically presents Classic at its declared default size, while the spatial volume remains suppressed until Play in 3D.
- The menu exposes Play, Play with Friends, Leaderboard, Rate, Support, and Settings. Play with Friends remains Classic-only and bypasses the solo play-limit gate.
- Play creates a fresh run with three lives, three lanes, five visible rows, and the saved difficulty.
- Restart resets score, lives, traffic, and progression in the current presentation. Finish resets the session, dismisses the volume, and returns to the Classic menu.
- Classic and spatial mode share the gameplay audio policy for start/resume, road ticks, lane movement/safety, speed warnings, crash/fail, and SharePlay countdown cues.
- Spatial mode is solo-only. Starting or receiving SharePlay while the volume is presented first acquires the SharePlay pause and returns the exact run to Classic.

## Shared Gameplay Authority

- The main-actor `GameEngine` owns timing, lane movement, traffic, scoring, difficulty, collision recovery, lives, pause reasons, restart, and finish.
- Renderers receive immutable `GameSnapshot` values and events. RealityKit transforms and animations never mutate gameplay.
- User, overlay, presentation transition, spatial ready, lifecycle, startup, and SharePlay pause reasons compose independently.
- Background wall time is never replayed after activation.

## Pushed-Volume Lifecycle

- **Play in 3D** is available during every solo Classic theme. Spatial mode always renders the canonical Polygon models and does not mutate the saved Classic theme.
- Entry acquires presentation-transition and spatial-ready pause reasons and preflights both models before pushing the volume from Classic.
- The volume is 0.60 × 0.30 × 0.80 m, uses `.volumeWorldAlignment(.gravityAligned)`, supports front-oriented viewpoints, and hides the system baseplate.
- `GeometryReader3D` centers the 0.55 × 0.75 m board in the volume and aligns the board underside with its bottom surface-snapping boundary.
- The lifecycle is inactive, preflighting, opening, ready, active, returning, or model failure. The renderer reports ready only after its fixed entity pools and ornaments are installed, then Classic is dismissed so only the volume remains visible and interactive.
- The ready Play/Resume action clears spatial-ready pause. If entry began while explicitly user-paused, that action clears both user and spatial-ready pause before the shared start cue.
- Return to 2D, system volume close, backgrounding, and SharePlay arrival are idempotent returns. They reopen Classic when needed, dismiss the volume, and preserve the exact snapshot and explicit user pause except when the user explicitly chooses Resume in the ready volume.
- Every asynchronous transition has an identity token. Duplicate requests and stale model, routing, renderer-ready, and dismissal callbacks cannot alter a newer presentation.

## Spatial Road and Models

- The board is 0.55 × 0.75 m. Its centered road is 0.45 × 0.70 m, with three 0.15 m lanes, five 0.14 m rows, 0.05 m side verges, and 0.025 m end verges.
- A fixed pool contains one player, fifteen rivals, twenty road dashes, one full-width finish strip, three lane targets, an impact burst, and player/rival collision-pose clones.
- Four road boundaries, including both outer edges, render across five logical rows. Four rows are visible and one is blank; the shared `RoadMarkerLayoutResolver` advances the blank only when `roadPhase` advances on a grid tick.
- The finish strip uses the shared `lapStripMask`, the Polygon lap-marker tint, and the same paired/virtual safety-row placement as SpriteKit. It suppresses overlapping dashes while passing through the board.
- Road, verge, boundary, and finish colors resolve from `SixtyFourBitTheme`, including its Increase Contrast variants.
- Each canonical model is normalized from finite measured bounds to at most 70% of lane width and 80% of row depth. Invalid bounds, missing enabled model descendants, empty materials, non-positive scale, non-finite post-normalization bounds, or road-volume escape are typed failures.
- A board-local directional key light uses approximately 2,000 lux with shadows disabled. Authored Polygon materials and emissive lamps remain intact.
- Player lane changes and rival row advances animate in the renderer over approximately 110 ms. Reduce Motion applies transforms immediately.
- Collision hides the normal cars and pulses both collision clones plus the impact burst three times at 120 ms intervals. Reduce Motion holds a steady, high-contrast, non-color-only silhouette.

## HUD, Input, and Accessibility

- The HUD and Return to 2D control are ordinary SwiftUI ornaments; RealityKit contains no SwiftUI view attachments.
- The standard visionOS ornament background and automatic appearance replace custom panel materials and forced color schemes.
- The HUD sits beyond the far road edge. It lays out score first, helmets next, and Level directly below the helmets. **3D Ready** has no explanatory subtitle.
- HUD text and controls use `FontPreferenceStore` semantic fonts. HUD buttons reuse `retroRacingSecondaryButtonStyle()` and use `Color.accentColor` for titles and symbols, matching Play with Friends. The Classic Play in 3D control retains its native title-and-icon ornament appearance.
- Ready shows one Play/Resume action; racing shows one Pause/Resume action; game over shows native Restart and Finish actions. A separate top ornament mirrors the Classic Play in 3D ornament for Return to 2D.
- Three transparent, full-road RealityKit lane targets own `CollisionComponent`, `InputTargetComponent`, accessibility metadata, and `GestureComponent`. They do not install a system hover effect or alter road rendering when input becomes active.
- Selecting a different lane emits one existing left/right command toward it. Selecting the current lane is a no-op. Keyboard arrows, controller input, Direct Touch, Magic Tap, named movement actions, and the adjustable lane action use the same command path.
- Localized accessibility values expose presentation state, score, lives, level, lane, and pause state. Focus returns to the primary action or current lane as appropriate.
- The spatial UI respects Dynamic Type, Reduce Motion, Reduce Transparency, Increase Contrast, Differentiate Without Color, VoiceOver, Voice Control, Switch Control, and Full Keyboard Access.
- Direct Touch is bounded to the Classic board and spatial road; native ornaments and window controls retain standard assistive navigation.

## Assets and Failure Policy

- The checked-in player USDA, rival USDA composition, generated USDZ files, fixed-camera sprite outputs, and shared lap-strip mask remain the canonical Polygon sources.
- Runtime loading validates distinct player and rival entities and clones the fixed pools; it never recolors a rival or substitutes shipping geometry.
- Model-load or visibility-validation failure logs a typed error, restores Classic, preserves the run, and presents localized recovery copy.

## Testing and Release Gate

- Coordinator tests cover push, Classic dismissal after renderer readiness, Classic restoration, ready-state pause ownership, Play/Resume, explicit user pause, cancellation, model failure, duplicates, stale callbacks, system close, backgrounding, repeated switching, Finish, SharePlay recovery, and exact snapshot preservation.
- Shared resolver tests cover every phase, finish-row pairs, edge sentinels, and dash suppression. RealityKit tests cover exact volume/board placement, twenty pooled dashes, inner/outer boundaries, finish texture and placement, marker reuse, contrast, non-highlighting lane targets, and absence of HUD attachments.
- Simulator acceptance covers replacement of Classic by the pushed volume, stable non-head-relative placement, system window-bar movement, ornament interaction, configured fonts, accent styling, and reliable Return to 2D.
- Physical Apple Vision Pro acceptance covers snapped and floating play, tables and desks, seated and standing viewing, focus/hit testing, repeated transitions, ten-minute stability, and the complete accessibility matrix.
- The public visionOS status remains **Coming Soon** until the physical-device gate passes. Automated tests and simulator rendering do not prove physical surface snapping, visibility, or comfort.
