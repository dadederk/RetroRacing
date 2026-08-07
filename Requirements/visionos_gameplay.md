# visionOS Gameplay

## Overview

The visionOS app presents one solo RetroRapid! run as either a Classic SwiftUI window or a surface-anchored RealityKit scene in a mixed `ImmersiveSpace`. Both renderers consume the same shared `GameEngine` snapshots; changing presentation never creates or advances a second run.

The spatial scene uses a privacy-preserving `AnchorEntity` configured for any horizontal plane with minimum bounds of 0.55 × 0.75 m. It does not request world-sensing authorization, render shipping fallback geometry when tracking is unavailable, or use TabletopKit. TabletopKit remains a possible future dependency for a spatial SharePlay mode, not the solo renderer or surface-placement lifecycle.

## Launch and Session

- The app opens in Classic on the shared universal-style menu and does not advance gameplay before Play.
- The menu exposes Play, Play with Friends, Leaderboard, Rate, Support, and Settings. Play with Friends remains Classic-only and bypasses the solo play-limit gate.
- Play creates a fresh run with three lives, three lanes, five visible rows, and the saved difficulty.
- Restart resets score, lives, traffic, and progression in the current presentation. Finish resets the session and returns to the Classic menu.
- Classic and spatial mode share the gameplay audio policy for start/resume, road ticks, lane movement/safety, speed warnings, crash/fail, and SharePlay countdown cues.
- Spatial mode is solo-only. Starting or receiving SharePlay while spatial content is presented first acquires the SharePlay pause and returns the exact run to Classic.

## Shared Gameplay Authority

- The main-actor `GameEngine` owns timing, lane movement, traffic, scoring, difficulty, collision recovery, lives, pause reasons, restart, and finish.
- Renderers receive immutable `GameSnapshot` values and events. RealityKit physics, transforms, and animations never mutate gameplay.
- User, overlay, presentation transition, spatial placement, lifecycle, startup, and SharePlay pause reasons compose independently.
- Background wall time is never replayed after activation.

## Spatial Placement Lifecycle

- **Play in 3D** is available during every solo Classic theme. Spatial mode always renders the canonical Polygon models and does not mutate the saved Classic theme.
- Entry acquires presentation-transition and spatial-placement pause reasons, preflights both models while Classic stays visible, then opens the mixed immersive space.
- Classic displays persistent surface-search guidance while a horizontal plane is sought. After ten seconds it adds troubleshooting guidance without cancelling the search; Return to 2D always remains available.
- The road, model pools, lane inputs, attached HUD, and plane anchor must all be ready before Classic is dismissed.
- Anchoring enters an explicit confirmation state. The user chooses **Resume in 3D** before the placement pause clears; an existing explicit user pause remains intact.
- Losing the anchor immediately reapplies spatial-placement pause, disables lane input, reopens Classic with recovery guidance, and starts reacquisition. A recovered anchor requires confirmation again.
- Model failure, immersive-open error or cancellation, system immersive dismissal, app backgrounding, or incoming SharePlay restores Classic with the exact snapshot and clears only the pause reasons owned by that transition.
- Every asynchronous transition has an identity token. Duplicate requests and stale model, routing, anchor, and dismissal callbacks cannot alter a newer presentation.

## Spatial Road and Models

- The board is 0.55 × 0.75 m and rests with its underside on the detected surface. Its centered road is 0.45 × 0.70 m, with three 0.15 m lanes, five 0.14 m rows, 0.05 m side verges, and 0.025 m end verges.
- Two continuous lane dividers sit flush above the road. Horizontal row seams are never rendered.
- Fixed pools contain one player, fifteen rivals, two safety markers, three lane targets, an impact burst, and player/rival collision-pose clones.
- Each canonical model is normalized from finite measured bounds to at most 70% of lane width and 80% of row depth. Invalid bounds, missing enabled model descendants, empty materials, non-positive scale, non-finite post-normalization bounds, or road-volume escape are typed failures.
- A board-local directional key light uses approximately 2,000 lux with shadows disabled. Authored Polygon materials and emissive lamps remain intact.
- Player lane changes and rival row advances animate in the renderer over approximately 110 ms. Reduce Motion applies transforms immediately.
- Collision hides the normal cars and pulses both collision clones plus the impact burst three times at 120 ms intervals. Reduce Motion holds a steady, high-contrast, non-color-only silhouette.

## HUD, Input, and Accessibility

- A native SwiftUI HUD is mounted upright beyond the far edge with visionOS `ViewAttachmentComponent`.
- Score is the largest element and uses monospaced digits. Lives reuse the Classic three-helmet strip, consuming helmets from left to right as lives are lost; level is secondary.
- Spatial action buttons use an explicit high-contrast accent and contrasting prominent-button labels so their titles and symbols remain legible against the dark HUD panel.
- Placement, racing, tracking recovery, and game-over states expose the actions defined by their state, including Resume in 3D, Pause/Resume, Restart, Finish, and Return to 2D.
- Three full-road RealityKit lane targets own `CollisionComponent`, `InputTargetComponent`, hover feedback, accessibility metadata, and `GestureComponent`.
- Selecting a different lane emits one existing left/right command toward it. Selecting the current lane is a no-op. Keyboard arrows, controller input, Direct Touch, Magic Tap, named movement actions, and the adjustable lane action use the same command path.
- Localized accessibility values expose placement state, score, lives, level, lane, and pause state. Focus returns to Resume in 3D, the current lane, or recovery guidance as appropriate.
- The spatial UI respects Dynamic Type, Reduce Motion, Reduce Transparency, Increase Contrast, Differentiate Without Color, VoiceOver, Voice Control, Switch Control, and Full Keyboard Access.
- Direct Touch is bounded to the Classic board and spatial road; native HUD and window controls retain standard assistive navigation.

## Assets and Failure Policy

- The checked-in player USDA, rival USDA composition, generated USDZ files, and fixed-camera sprite outputs remain the canonical Polygon sources.
- Runtime loading validates distinct player and rival entities and clones the fixed pools; it never recolors a rival or substitutes shipping geometry.
- Model-load or visibility-validation failure logs a typed error, restores Classic, preserves the run, and presents localized recovery copy.

## Testing and Release Gate

- Coordinator tests cover entry, confirmation-gated resume, stacked user pause, cancellation, typed failures, duplicates, stale callbacks, anchor recovery, system exit, backgrounding, repeated switching, and SharePlay recovery.
- RealityKit tests cover exact dimensions, surface-relative height, lane hit regions and gestures, model/material visibility, fixed and collision pools, HUD readiness, theme independence, and accessibility visual variants.
- Debug simulator composition uses a deterministic head-relative preview anchor so the board appears at a stable testing position instead of attaching to an arbitrary simulated plane. Tests may inject a fixed world anchor. Device and release composition always use the detected-plane provider; neither preview mechanism is a shipping placement fallback.
- Physical Apple Vision Pro acceptance covers tables, desks and other horizontal surfaces; bright/dim rooms; seated/standing viewing; unmistakable red/cyan models; HUD legibility; collisions; repeated transitions; anchor loss; system exit; ten-minute stability; and the complete accessibility matrix.
- The public visionOS status remains **Coming Soon** until the physical-device gate passes. Automated tests and simulator rendering do not prove physical visibility or comfort.
