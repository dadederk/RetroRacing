# visionOS Gameplay

## Overview

The visionOS app presents one solo RetroRapid! run as either a Classic SwiftUI window or a RealityKit tabletop volume. Classic targets gameplay and menu parity with iPadOS/macOS while retaining native visionOS controls. Both renderers consume the same shared `GameEngine` snapshots; presentation changes never create another run.

## Launch and Session

- The app opens in Classic presentation on the shared universal-style menu and does not advance gameplay before Play.
- The menu exposes Play, Play with Friends, Leaderboard, Rate, Support, and one Settings button in the top-right corner. Play is the visually prominent primary action and uses the app accent color. Play with Friends starts or joins the shared two-player Group Activity and bypasses the solo play-limit gate.
- Polygon is the free default and cannot be disabled. The shared Style Gallery shows all six themes; Unlimited Plays users can select any of them for Classic gameplay, while free users can inspect the locked styles. Disc and Polygon are permanent visionOS catalog entries and therefore do not have Debug theme toggles.
- The shared Settings surface exposes the applicable speed, theme, font, road, Big Cars, Direct Touch, purchase, controls, and About options. The selected speed, font, theme, road, and car-size preferences apply to Classic gameplay.
- Play creates a fresh run with three lives, three lanes, five visible rows, and the current saved difficulty.
- Restart resets score, lives, traffic, and progression in the current presentation.
- Classic gameplay provides a top-left X button that presents the shared Finish this game alert with Keep Playing and Finish actions. A top-right Pause/Resume button replaces Settings during the run, and Settings remains available from the main menu. Finish stops the loop, resets the session, restores Classic when needed, and returns to the main menu.
- The Leaderboard menu action opens the Game Center leaderboard browser, and the Rate action uses the shared App Store review route.
- SharePlay is supported in Classic presentation. A long-lived app observer accepts incoming and continued sessions even while Classic is off-screen. Incoming SharePlay while Tabletop is active automatically returns to Classic; a failed handoff leaves the group session and reports the failure. Tabletop entry is disabled for the duration of a match.
- visionOS submits only the local player's completed SharePlay score through the existing difficulty-specific leaderboard path. Solo score submission and achievement completion remain outside this increment.
- Classic and Tabletop both use the shared gameplay audio policy: start/resume, road ticks, lane movement/safety, speed warning, crash/fail, and SharePlay countdown/go cues. visionOS does not expose haptics-only choices.

## Shared Gameplay

- The main-actor `GameEngine` owns timing, lane movement, traffic, scoring, difficulty progression, collision recovery, lives, pause reasons, restart, and finish.
- Renderers receive immutable `GameSnapshot` values and must not mutate gameplay state directly.
- Traffic generation always leaves at least one empty lane in a newly generated row.
- Passing a traffic row scores one point per rival in that row.
- Collision immediately consumes one life. The presentation holds the collision state through the fail cue (with the shared completion fallback), then asks the engine to reset the visible grid while preserving score and the traffic sequence.
- Resolving a collision with zero lives enters game over.
- User, overlay, presentation-transition, app-lifecycle, and SharePlay pause reasons compose independently. Background wall time is never replayed after activation.
- SpriteKit platforms consume the same engine through `GameScene`; existing rendering and service delegates remain platform-owned.

## Presentations

- Classic embeds the shared SpriteKit `GameScene` in renderer-only mode and feeds it the coordinator's immutable snapshots. It therefore uses the same square road, road-surface overhang, car/crash sizing, marker assets, and collision presentation as iPadOS/macOS without starting a second gameplay engine. The square fits within the available gameplay height and retains a visible bottom inset from the window edge. Simplified Grid and Big Cars retain their shared precedence.
- Tabletop renders a 0.90 m square raised board inside a 1.04 × 0.65 × 1.04 m volume. Its centered 0.51 × 0.85 m road has three 0.17 m lanes, five 0.17 m rows, symmetric 0.195 m side verges, straight parallel lane dividers rendered as flush planes over the road, and no visible horizontal row seams.
- Every Tabletop car model is normalized once inside an exact cell anchor from its measured local bounds and fits within 58% of its cell width and 64% of its cell depth. Snapshot updates move only the fixed player and fifteen rival anchors, so model-origin offsets cannot collapse traffic into the center lane. Safety markers and the procedural impact burst are also fixed pools.
- The top ornament reads **Play in 3D** in Classic. Tabletop uses a larger native top panel lifted above the volumetric gameplay surface; **Return to 2D** remains in that panel.
- The **Play in 3D** ornament is available only while Polygon is selected because Tabletop uses the canonical 64-Bit model. Selecting any other theme changes Classic colors and sprites and leaves Tabletop unavailable.
- Classic and Tabletop are single-instance windows. The candidate uses `pushWindow`; an injected explicit open-before-dismiss strategy remains available if device QA rejects cross-style push restoration.
- A presentation pause is acquired before handoff and cleared only when the destination renderer reports its model, board, native top panel, and input surfaces ready.
- Each handoff has an identity token. Duplicate requests and stale readiness callbacks are ignored.
- A two-second readiness timeout restores the source, clears only the transition pause, restores focus, and presents a localized retry message without changing the run.
- Closing the tabletop with system window chrome restores Classic without changing score, lives, lane, traffic, or session identity.
- Tabletop can return to Classic during active play, pause, collision, or game over. Game-over handoff preserves the exact snapshot and keeps the game-over presentation active in Classic.
- A SharePlay state received in Tabletop acquires the SharePlay pause before requesting the Classic handoff. The latest state is applied only after Classic acknowledges readiness; transition failure leaves SharePlay rather than starting a spatial round.

## Controls and Accessibility

- Classic uses its three bounded SpriteKit board lanes as the gaze-and-pinch movement interface and has no separate control row below the square. Tabletop uses its three full-road semantic RealityKit lane targets as the visible gaze-and-pinch movement interface and has no visible Left/Right buttons.
- Selecting a lane on either side emits one discrete move toward it; selecting the current lane is a no-op. Tabletop retains Direct Touch, lane hover, keyboard/controller input, Magic Tap, named movement actions, and the adjustable lane control.
- The high-contrast Tabletop panel is native SwiftUI mounted above the volume rather than a RealityKit attachment, so its status and buttons cannot be occluded or clipped by 3D content. It always shows score, lives, and level as visible text. During a run it shows Pause/Resume and Return to 2D; at game over it shows Game Over, Restart, Finish, and Return to 2D.
- Magic Tap toggles pause during an active run.
- The Classic HUD uses the selected shared semantic font and theme life-helmet assets at the same visual hierarchy as the iPadOS/macOS HUD. SwiftUI exposes score, lives, lane, movement, pause, restart, and finish with localized labels and predictable focus after handoffs and errors.
- During collision, Tabletop hides the player model and pulses one pooled low-poly impact burst at the player cell for the engine-owned collision phase. Game over holds the burst steady; recovery and restart hide it. Reduce Motion uses a steady non-blinking state, while Increase Contrast and Differentiate Without Color retain a distinct raised silhouette.
- The Direct Touch setting applies only to the bounded Classic SpriteKit board and tabletop road. HUD, ornaments, Settings, and native controls retain standard assistive navigation.

## 64-Bit Assets

- The dated player USDA, dedicated rival USDA composition, and checked-in camera configuration remain canonical for the two visionOS car models and their fixed-camera projections. The shared runtime catalog contains explicit optimized visionOS player, rival, crash, player-life, and friend-life renditions for the 32-Bit and 64-Bit Classic sprite families.
- The canonical rival model reuses the proven boxed player geometry while baking the cyan material family, removing the helmet `X` and player lamps, activating one vertical two-lamp stack on each side, and retaining exactly four exhaust tubes. The fixed-camera visionOS rival sprite and all five additional platform renditions are rendered from that composed model rather than an ImageGen or hue-shifted raster.
- The runtime loads and validates the distinct player and rival entities once, then clones a fixed pool of one player and fifteen rivals. Render updates retain direct entity references.
- Model-load or validation failure never silently substitutes shipping geometry: the app logs the typed failure, restores a usable Classic race, and exposes a localized retry message.
- The generated player car becomes a release candidate only after physical-device scale, lighting, silhouette, 2D/3D correspondence, and comfort approval.
- Classic collision feedback is the shared SpriteKit crash presentation: the player car is replaced with the selected theme's aspect-fitted crash sprite and shared blink timing, while Reduce Motion uses the shared fade. Tabletop uses its pooled procedural burst and does not add a crash asset to the spatial pipeline. Canonical 3D crash/helmet models and physical-device art approval remain planned work.

## Testing

- Shared tests cover deterministic traffic, lane bounds, engine-owned collision timing, stacked pause reasons, lifecycle discontinuities, restart, seeded continuity, and SpriteKit adapter equivalence.
- visionOS tests cover Play gating, current difficulty application, shared gameplay audio routing, SharePlay countdown de-duplication, Classic match start, Tabletop-to-Classic SharePlay handoff, stacked overlay/user pause, menu movement guards, shared SpriteKit snapshot rendering, tokenized handoff and recovery (including game over), square Tabletop geometry, model-bounds scaling, semantic lane bounds, snapshot-positioned markers, dense-grid separation, pooled identity, collision-effect states, bounded Direct Touch configuration, model loading, and unmarked rival geometry.
- Shared and script tests cover theme catalogs, 64-Bit palette/asset decoding, platform-aware destination resolution, deterministic spatial assets, and deterministic cross-platform runtime renditions.
- Manual device QA covers repeated handoffs, system volume dismissal, window sizing, gaze/pinch, Direct Touch, keyboard/controller, VoiceOver, Voice Control, Switch Control, motion/contrast preferences, frame pacing, memory stability, and physical scale.
- Passing these gates creates a signed release candidate only. Public **Coming Soon** status remains until separate product and App Store approval.
