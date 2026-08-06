# visionOS Gameplay

## Overview

The visionOS vertical slice presents one solo RetroRapid! run as either a Classic SwiftUI window or a RealityKit tabletop volume. Both renderers consume the same shared `GameEngine` snapshots; presentation changes never create another run.

## Launch and Session

- The app opens in Classic presentation on a small Play screen and does not advance gameplay before Play.
- Polygon is the free default and cannot be disabled. Debug Settings exposes Disc as an optional Classic theme; builds without Debug UI retain only Polygon.
- Play creates a fresh run with three lives, three lanes, five visible rows, and the accessibility-derived default difficulty.
- Restart resets score, lives, traffic, and progression in the current presentation.
- Finish stops the loop, resets the session, restores Classic when needed, and returns to the Play screen.
- Game Center, achievements, play limits, SharePlay, complete Settings parity, and gameplay audio are outside this vertical slice.

## Shared Gameplay

- The main-actor `GameEngine` owns timing, lane movement, traffic, scoring, difficulty progression, collision recovery, lives, pause reasons, restart, and finish.
- Renderers receive immutable `GameSnapshot` values and must not mutate gameplay state directly.
- Traffic generation always leaves at least one empty lane in a newly generated row.
- Passing a traffic row scores one point per rival in that row.
- Collision immediately consumes one life. Engine ticks hold the collision state for 750 ms of active gameplay time, then reset the visible grid while preserving score and the traffic sequence.
- Resolving a collision with zero lives enters game over.
- User, overlay, presentation-transition, and app-lifecycle pause reasons compose independently. Background wall time is never replayed after activation.
- SpriteKit platforms consume the same engine through `GameScene`; existing rendering and service delegates remain platform-owned.

## Presentations

- Classic renders the square road, cars, markers, and collision feedback with SwiftUI `Canvas`.
- Tabletop renders a compact three-lane road, the player car, and pooled rival clones in a volumetric `RealityView`.
- The top ornament reads **Play in 3D** in Classic and **Return to 2D** in Tabletop.
- The **Play in 3D** ornament is available only while Polygon is selected because Tabletop uses the canonical 64-Bit model. Selecting the Debug-only Disc theme changes Classic colors and sprites and leaves Tabletop unavailable.
- Classic and Tabletop are single-instance windows. The candidate uses `pushWindow`; an injected explicit open-before-dismiss strategy remains available if device QA rejects cross-style push restoration.
- A presentation pause is acquired before handoff and cleared only when the destination renderer reports its model, scene, HUD, controls, and input surfaces ready.
- Each handoff has an identity token. Duplicate requests and stale readiness callbacks are ignored.
- A two-second readiness timeout restores the source, clears only the transition pause, restores focus, and presents a localized retry message without changing the run.
- Closing the tabletop with system window chrome restores Classic without changing score, lives, lane, traffic, or session identity.

## Controls and Accessibility

- Gaze-and-pinch buttons move left/right and pause/resume; keyboard arrows and Space provide equivalent commands.
- Classic exposes three tap lanes and Tabletop exposes three semantic RealityKit lane targets. Selecting a lane on either side emits one discrete move toward it; selecting the current lane is a no-op.
- Native buttons, named lane actions, and an adjustable lane control remain available without exploring 3D geometry.
- Magic Tap toggles pause during an active run.
- SwiftUI exposes score, lives, lane, movement, pause, restart, and finish with localized labels and predictable focus after handoffs and errors.
- Reduce Motion removes nonessential interpolation; Increase Contrast and Differentiate Without Color preserve road, lane, collision, and status legibility.
- The Direct Touch setting applies only to the bounded Canvas board and tabletop road. HUD, ornaments, Settings, and native controls retain standard assistive navigation.

## 64-Bit Assets

- The dated player USDA, dedicated rival USDA composition, and checked-in camera configuration remain canonical for the two visionOS car models and their fixed-camera projections. The shared runtime catalog contains optimized player, rival, crash, player-life, and friend-life 64-Bit sprite families for every supported platform idiom, including the visionOS player and rival projections used by Classic.
- The canonical rival model reuses the proven boxed player geometry while baking the cyan material family, removing the helmet `X` and player lamps, activating one vertical two-lamp stack on each side, and retaining exactly four exhaust tubes. The fixed-camera visionOS rival sprite and all five additional platform renditions are rendered from that composed model rather than an ImageGen or hue-shifted raster.
- The runtime loads and validates the distinct player and rival entities once, then clones a fixed pool of one player and fifteen rivals. Render updates retain direct entity references.
- Model-load or validation failure never silently substitutes shipping geometry: the app logs the typed failure, restores a usable Classic race, and exposes a localized retry message.
- The generated player car becomes a release candidate only after physical-device scale, lighting, silhouette, 2D/3D correspondence, and comfort approval.
- Canonical 3D crash/helmet models and physical-device art approval remain planned work; the canonical player and rival car models plus the complete shared 2D runtime family are implemented.

## Testing

- Shared tests cover deterministic traffic, lane bounds, engine-owned collision timing, stacked pause reasons, lifecycle discontinuities, restart, seeded continuity, and SpriteKit adapter equivalence.
- visionOS tests cover Play gating, tokenized handoff and recovery, push/explicit routing, semantic lanes, bounded Direct Touch configuration, model loading, fixed pooling, and unmarked rival geometry.
- Shared and script tests cover theme catalogs, 64-Bit palette/asset decoding, platform-aware destination resolution, deterministic spatial assets, and deterministic cross-platform runtime renditions.
- Manual device QA covers repeated handoffs, system volume dismissal, window sizing, gaze/pinch, Direct Touch, keyboard/controller, VoiceOver, Voice Control, Switch Control, motion/contrast preferences, frame pacing, memory stability, and physical scale.
- Passing these gates creates a signed release candidate only. Public **Coming Soon** status remains until separate product and App Store approval.
