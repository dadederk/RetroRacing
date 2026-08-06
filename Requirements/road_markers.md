# Road Markers

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Road-marker overlay rendering, road-style modes, Big Cars precedence, lap marker timing, and contrast.
- **Must not break:** Rendering stays in `GameScene+Grid.swift`; transient line overlays clear/redraw each grid refresh; persistent road surfaces rebuild only when their render signature changes; Big Cars forces vertical-only markers; generated lap-strip mask assets are verified through Scripts.
- **Key files:** `GameScene+Grid.swift`, `generate-road-dash-masks`, theme road-line colors.

## Behavior Contract

- Road surface fills come from `theme.gridCellColor()`.
- Themes can optionally provide `theme.roadExteriorColor()` for the field outside the perspective road.
- Transient line/lap visuals are tracked by `lineOverlayNodes`; persistent perspective fills are tracked separately by `roadSurfaceNodes`.
- Precedence:
  1. Big Cars on: vertical-only dashed separators.
  2. Big Cars off + Simplified Grid: vertical-only continuous separators.
  3. Big Cars off + Detailed Road: perspective dashed road markers and lap strips.
- Horizontal grid lines remain hidden in all road-marker modes.
- Lane moves do not advance dash phase; grid tick updates do.

## Detailed Road

- Uses one shared perspective road model from top width ratio `0.38` to bottom width ratio `0.94`.
- Themes with a road-exterior color draw row-by-row perspective road-surface overlays from that model, expanded past the outer lane boundaries so the road color sits under the full outer lines with a generous overhang.
- Road surfaces are cached by scene size, theme identity, road style, Big Cars state, and line mode. Grid ticks and lane moves preserve node identity; resize, theme/style, or mode changes rebuild them.
- Each visible row renders four trapezoid marker segments: outer-left, inner-left, inner-right, outer-right.
- Perspective marker trapezoids use an antialiased matching edge stroke so their diagonal edges remain smooth on watch-sized displays.
- Marker thickness and car/rival/crash scaling follow depth so lane alignment remains centered.
- Dashed markers are suppressed where lap strips render.

## Lap Markers

- `lapStripMask` is a generated shared white mask with explicit iPhone, iPad, Mac, Apple Watch, and Apple TV variants. The visionOS vertical slice renders equivalent safety markers directly in Canvas and RealityKit rather than shipping this SpriteKit mask.
- Lap strips render only during the two-row safety empty window before a speed increase.
- Safety marker rows shift with grid movement and retain one off-screen sentinel so the strip exits smoothly.
- Verify generated assets without rewriting:

```bash
swift run --package-path Scripts generate-road-dash-masks --check
./retrorapid assets audit --check
```

## Big Cars and Simplified Grid

- Big Cars hides perspective road/lap markers and uses fixed in-cell car sizing for all cars/crashes.
- Big Cars separators are flat dashed vertical segments with 4-on/1-off cadence.
- Simplified Grid hides perspective markers and uses two continuous vertical separators.

## Contrast

- Road-line tint comes from `theme.roadLineColor(isIncreaseContrastEnabled:)`; finish/lap strips use `theme.lapMarkerColor(isIncreaseContrastEnabled:)`.
- Increase Contrast must switch to dedicated high-contrast road-line colors.
- Non-text road and finish/lap markers must maintain at least 3:1 contrast against road fills.

## Testing

- Tests cover dash phase, Big Cars precedence, simplified/detailed modes, persistent surface identity/invalidation, lap strip timing/continuity, hidden horizontal lines, lane-center alignment, depth convergence, generated mask drift, asset-footprint drift, and contrast resolver output.

## Related

- [theming_system.md](theming_system.md)
- [accessibility.md](accessibility.md)
