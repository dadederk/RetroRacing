# visionOS Surface-Anchored Spatial Game Plan

**Status:** Anchored implementation in automated validation — physical-device approval pending

**See also:** [visionOS gameplay](../Requirements/visionos_gameplay.md) · [Requirements index](../Requirements/INDEX.md) · [Theming](../Requirements/theming_system.md) · [Accessibility](../Requirements/accessibility.md)

## Goal

Ship one continuous solo RetroRapid! run with two renderers:

- **Classic:** the window-based game and menu.
- **Spatial:** a compact 3D Polygon road placed automatically on a detected table or other horizontal surface in a mixed immersive space.

The shared `GameEngine` remains authoritative. Spatial presentation changes only rendering, input surfaces, and cosmetic animation.

## Decisions

- Use a mixed `ImmersiveSpace` with `AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: [0.55, 0.75]))`.
- Use the privacy-preserving anchor flow for v1; do not request world-sensing authorization or provide shipping fallback geometry.
- Do not adopt TabletopKit for solo v1. It does not provide the required physical-surface anchoring and would duplicate the engine's rule authority. Reconsider it for spatial SharePlay equipment and synchronization.
- Automatically select the first suitable surface, then require explicit Resume in 3D confirmation.
- Spatial mode always uses canonical Polygon models while preserving the selected Classic theme.
- Keep spatial mode solo-only and retain public **Coming Soon** status until physical-device acceptance passes.

## Implemented Vertical Slice

### Presentation and recovery

- Replaced the volumetric window with one mixed immersive space and injected immersive-space and surface-anchor protocols.
- Added an equatable state machine for inactive, preflighting, opening, surface search, confirmation, active racing, recovery, return, and typed failure.
- Added independent spatial-placement pause ownership alongside transition, user, lifecycle, overlay, startup, and SharePlay reasons.
- Preflighted canonical models before opening spatial content and kept Classic available during placement search.
- Added persistent search/recovery guidance, ten-second troubleshooting escalation without timeout, confirmation-gated resume, exact-snapshot restoration, and tokenized cancellation.
- Added anchor-loss recovery, system-dismissal recovery, background return, and SharePlay-to-Classic handoff.

### RealityKit renderer

- Built a 0.55 × 0.75 m surface-relative board with a 0.45 × 0.70 m road, three lanes, five rows, straight dividers, and no horizontal seams.
- Kept fixed pools for player, rivals, safety markers, lane targets, collision cars, and impact geometry.
- Replaced scale fallback with typed visibility validation for bounds, scale, enabled model descendants, materials, placement, and finite world bounds.
- Added a neutral 2,000-lux board-local directional key light with shadows disabled.
- Added short renderer-only car transitions and three-pulse dual-car collision feedback, with immediate/steady Reduce Motion variants.

### HUD, controls, and accessibility

- Mounted a native SwiftUI HUD with `ViewAttachmentComponent` beyond the far road edge.
- Added large monospaced score, helmet-plus-number lives, level, placement/racing/recovery/game-over states, and native actions.
- Applied collision, input-target, hover, accessibility, and visionOS gesture components to full-road lane targets.
- Preserved keyboard/controller, Direct Touch, Magic Tap, named actions, and adjustable lane input.
- Added focus restoration and layouts/material variants for Dynamic Type, Reduce Transparency, contrast, motion, and color differentiation.
- Added all new UI and failure strings across the 20 supported localization variants; non-English strings remain in the normal fluent-review workflow.

## Automated Gate

Run from the repository root:

```bash
./retrorapid test package
./retrorapid assets spatial --check
./retrorapid assets audit --check
./retrorapid check
./retrorapid test --platform all
./retrorapid docs
```

The visionOS suite must cover successful entry, pause composition, cancellation, model/open failures, duplicate and stale callbacks, anchor loss/reacquisition, system exit, backgrounding, repeated switches, SharePlay recovery, exact geometry, model/material visibility, collision pools, HUD readiness, theme independence, and accessibility variants.

## Physical Apple Vision Pro Gate

Automated loading and bounds tests do not prove visible content on device. Release evidence must record:

- tables, desks, and other horizontal surfaces in bright and dim rooms;
- seated and standing placement and comfortable reach/viewing distance;
- unmistakably visible red player and cyan rival cars with authored materials and lamps;
- large, legible HUD and usable gaze/pinch lane targets;
- crash pulses and steady Reduce Motion collision silhouette;
- repeated 2D/3D transitions, explicit cancellation, anchor loss/recovery, backgrounding, SharePlay arrival, and system immersive dismissal;
- ten-minute races with stable memory, frame pacing, lighting, and thermal behavior;
- VoiceOver, Voice Control, Switch Control, Full Keyboard Access, Direct Touch, Dynamic Type, Reduce Motion, Reduce Transparency, Increase Contrast, and Differentiate Without Color.

The removed volumetric route remains available in git history only. Do not restore it as a runtime fallback. If the anchored vertical slice fails physical visibility or lifecycle validation, correct the anchored implementation before public release.

## Deferred

- spatial SharePlay and TabletopKit;
- explicit plane selection and world-sensing permission;
- movable-volume fallback, free camera, draggable cars, multiple board sizes, and per-theme 3D model families;
- App Store availability and spatial screenshots, which remain blocked on the physical-device gate.
