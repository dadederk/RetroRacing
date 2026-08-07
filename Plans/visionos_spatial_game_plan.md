# visionOS Pushed-Volume Spatial Game Plan

**Status:** Pushed-volume implementation in automated validation — physical-device approval pending

**See also:** [visionOS gameplay](../Requirements/visionos_gameplay.md) · [Requirements index](../Requirements/INDEX.md) · [Road markers](../Requirements/road_markers.md) · [Accessibility](../Requirements/accessibility.md)

## Goal

Ship one continuous solo RetroRapid! run with two renderers:

- **Classic:** the window-based game and menu.
- **Spatial:** a compact 3D Polygon road in a gravity-aligned volumetric window that stays where the user places it and can snap to a horizontal surface.

The shared `GameEngine` remains authoritative. Spatial presentation changes only rendering, input surfaces, and cosmetic animation.

## Decisions

- Push a `.volumetric` `WindowGroup` from Classic with a 0.60 × 0.30 × 0.80 m default size, gravity alignment, front viewpoints, and hidden baseplate. Dismiss Classic after renderer readiness and reopen it during return so only one renderer is visible and playable.
- Use native system placement, window-bar movement, and visionOS surface snapping. Floating play is valid; do not request world-sensing authorization or add a custom placement gesture.
- Do not use an immersive space, head-relative simulator anchor, plane search, or TabletopKit for solo v1. Reconsider TabletopKit only for future spatial SharePlay equipment and synchronization.
- Spatial mode always uses canonical Polygon models while preserving the selected Classic theme.
- Keep spatial mode solo-only and retain public **Coming Soon** status until physical-device acceptance passes.

## Implemented Vertical Slice

### Presentation and recovery

- Replaced immersive-space and surface-anchor routing with injected push-volume, open-window, and dismiss-window operations.
- Reduced lifecycle state to inactive, preflighting, opening, ready, active, returning, and typed model failure.
- Added independent spatial-ready pause ownership alongside transition, user, lifecycle, overlay, startup, and SharePlay reasons.
- Preflighted canonical models before pushing the volume, report ready only after the RealityKit scene is installed, and then dismiss Classic.
- Made Return to 2D, system close, backgrounding, and SharePlay-to-Classic handoff reopen Classic exactly once while preserving the exact run snapshot.
- Kept transition identity tokens so cancelled, duplicate, or stale callbacks cannot affect a newer presentation.

### RealityKit renderer

- Built a 0.55 × 0.75 m board against the volume's bottom snapping boundary with a 0.45 × 0.70 m road, three lanes, and five rows.
- Kept fixed pools for player, rivals, lane targets, collision cars, and impact geometry.
- Added twenty pooled road-dash planes across the two inner and two outer road boundaries. Four rows render and one gap advances only with shared `roadPhase` ticks.
- Replaced two safety lines with one pooled full-width finish strip using `lapStripMask`, Polygon lap tint, and shared SpriteKit-equivalent paired/virtual safety-row placement.
- Resolved road, verge, boundary, and finish colors from `SixtyFourBitTheme`, including contrast behavior.
- Kept typed visibility validation, a neutral 2,000-lux board-local key light, renderer-only car transitions, and Reduce Motion collision variants.

### HUD, controls, and accessibility

- Replaced the RealityKit `ViewAttachmentComponent` HUD with ordinary SwiftUI ornaments.
- Put the status HUD beyond the far road edge and Return to 2D in a separate top ornament.
- Reused `GameScoreStatusView`, `GameLivesStatusView`, `FontPreferenceStore`, and `retroRacingSecondaryButtonStyle()` with native visionOS ornament backgrounds and accent-colored labels.
- Ordered score, helmets, then Level below the helmets; retained **3D Ready** without a subtitle.
- Exposed one Play/Resume action while ready, one Pause/Resume action while racing, and Restart/Finish at game over.
- Preserved controller/keyboard input, Direct Touch, Magic Tap, named and adjustable lane actions, focus restoration, Dynamic Type, and accessibility variants.
- Kept lane targets transparent and non-highlighting so enabling input cannot cover the road or cars with a system hover material.

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

The visionOS suite must cover successful push, one-window-at-a-time Classic dismissal/restoration, pause composition, Play/Resume, explicit user pause, cancellation, model failure, duplicates, stale callbacks, system close, backgrounding, repeated switches, Finish, SharePlay recovery, exact volume/board geometry, twenty pooled markers, outer boundaries, finish texture/placement, model/material visibility, non-highlighting lane targets, collision pools, ornament-only HUD, and accessibility variants.

## Simulator Gate

- The ready volume replaces and hides Classic in place and never follows simulated head movement.
- The system window bar moves the volume.
- HUD and Return ornaments respond reliably and use configured fonts and menu-consistent accent styling.
- Repeated 2D/3D transitions preserve one run; only the active presentation is visible, and Return reliably reopens Classic.

## Physical Apple Vision Pro Gate

Automated loading and bounds tests do not prove visible content or native snapping on device. Release evidence must record:

- horizontal surface snapping plus valid floating play when unsnapped;
- table and desk placement in bright and dim rooms;
- seated and standing placement and comfortable reach/viewing distance;
- unmistakably visible red player and cyan rival cars with authored materials and lamps;
- large, legible ornaments and usable gaze/pinch lane targets;
- repeated 2D/3D transitions, system volume close, backgrounding, and SharePlay arrival;
- ten-minute races with stable memory, frame pacing, lighting, and thermal behavior;
- VoiceOver, Voice Control, Switch Control, Full Keyboard Access, Direct Touch, Dynamic Type, Reduce Motion, Reduce Transparency, Increase Contrast, and Differentiate Without Color.

## Deferred

- spatial SharePlay and TabletopKit;
- custom surface classification, explicit plane selection, and world-sensing permission;
- free camera, draggable cars, multiple board sizes, and per-theme 3D model families;
- App Store availability and spatial screenshots, which remain blocked on the physical-device gate.
