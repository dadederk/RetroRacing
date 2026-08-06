# 64-Bit Sprite Generation Prompts

Generated with the built-in ImageGen tool on 6 August 2026. The player car
comes from the deterministic visionOS spatial-asset workflow. The rival prompt
below records a superseded concept only: the canonical rival is now the boxed
`RivalCar/rival-car-64bit.usda` composition, and its fixed-camera raster is
rendered deterministically from that 3D source. The fixed-camera player render
remains the style and palette anchor for the other ImageGen-derived assets.

## Shared direction

Create one original late-1990s low-polygon console sprite with chunky facets,
restrained vertex colors, crisp low-resolution stepping, simple baked lighting,
and a readable small-scale silhouette. Center the subject with even padding on
a flat `#00ff00` chroma background. Do not add a floor, shadow, scenery, text,
logo, watermark, or commercial console identity.

## Asset directions

- Superseded rival concept: create a centered, strict rear-orthographic teal/cyan
  rear-engined open-wheel car. Preserve the current 64-Bit low-poly palette,
  broad silhouette, stepped edges, wide rear wing, dark rear grille, and
  exposed angular suspension. Import the established rival identity from the
  16-Bit and 32-Bit references: an entirely plain helmet with no `X`, cross,
  letter, number, logo, stripe intersection, or other mark; one vertical light
  housing on each side with exactly two stacked glowing lamps; and exactly four
  large round exhaust openings arranged as two symmetric pairs. Keep the whole
  car visible with even padding on a perfectly flat `#00ff00` chroma background
  with no floor, shadow, reflection, gradient, texture, scenery, text,
  watermark, or commercial identity. Do not produce a perspective or front
  view, horizontal-only lights, or any number of exhausts other than four.
- Player helmet: red low-poly shell, dark-navy visor, warm-orange accents, and
  one large warm-ivory side `X` matching the player-car identity.
- Friend helmet: cyan/teal low-poly shell, dark-navy visor, a restrained
  warm-orange accent, and no mark, symbol, letter, or number.
- Crash: one compact opaque faceted impact burst in yellow, orange, player red,
  cyan, and graphite, with exactly one readable detached wheel and no smoke.

The chroma-key helper used automatic border sampling, soft matte, thresholds
12/220, and despill for the remaining generated assets and the archived rival
concept. The shipping rival uses the spatial workflow's software orthographic
renderer at low resolution followed by nearest-neighbor enlargement; this
keeps the visionOS sprite below its 25 KB source budget while retaining the
requested mechanical details. Its platform variants use point scaling from
that same model render. Other curated variants use Lanczos normalization,
Riemersma dithering, and a bounded 256-color RGBA palette.
