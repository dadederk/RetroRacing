# Road Markers

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Road-marker overlay rendering, road-style modes, Big Cars precedence, lap marker timing, and contrast.
- **Must not break:** Rendering stays in `GameScene+Grid.swift`; overlays clear/redraw each grid refresh; Big Cars forces vertical-only markers; generated mask assets are verified through Scripts.
- **Key files:** `GameScene+Grid.swift`, `generate-road-dash-masks`, theme road-line colors.

## Behavior Contract

- Cell fills still come from `theme.gridCellColor()`.
- Line visuals are overlays tracked by `lineOverlayNodes`.
- Precedence:
  1. Big Cars on: vertical-only dashed separators.
  2. Big Cars off + Simplified Grid: vertical-only continuous separators.
  3. Big Cars off + Detailed Road: perspective dashed road markers and lap strips.
- Horizontal grid lines remain hidden in all road-marker modes.
- Lane moves do not advance dash phase; grid tick updates do.

## Detailed Road

- Uses one shared perspective road model from top width ratio `0.38` to bottom width ratio `0.94`.
- Each visible row renders four trapezoid marker segments: outer-left, inner-left, inner-right, outer-right.
- Marker thickness and car/rival/crash scaling follow depth so lane alignment remains centered.
- Dashed markers are suppressed where lap strips render.

## Lap Markers

- `lapStripMask` is a generated shared white mask with universal/watch/tv variants.
- Lap strips render only during the two-row safety empty window before a speed increase.
- Safety marker rows shift with grid movement and retain one off-screen sentinel so the strip exits smoothly.
- Verify generated assets without rewriting:

```bash
swift run --package-path Scripts generate-road-dash-masks --check
```

## Big Cars and Simplified Grid

- Big Cars hides perspective road/lap markers and uses fixed in-cell car sizing for all cars/crashes.
- Big Cars separators are flat dashed vertical segments with 4-on/1-off cadence.
- Simplified Grid hides perspective markers and uses two continuous vertical separators.

## Contrast

- Marker tint comes from `theme.roadLineColor(isIncreaseContrastEnabled:)`.
- Increase Contrast must switch to dedicated high-contrast road-line colors.
- Road line colors should target approximately 4.5:1 contrast against road fills.

## Testing

- Tests cover dash phase, Big Cars precedence, simplified/detailed modes, lap strip timing/continuity, hidden horizontal lines, lane-center alignment, depth convergence, generated mask drift, and contrast resolver output.

## Related

- [theming_system.md](theming_system.md)
- [accessibility.md](accessibility.md)
