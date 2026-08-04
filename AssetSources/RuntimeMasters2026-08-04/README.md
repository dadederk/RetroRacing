# Runtime Masters 2026-08-04

Canonical runtime inputs for the revised 8-Bit player car.

- The car preserves the established straight-on rear view, exposed tires, rear
  wing, red player identity, and light helmet `X`.
- The artwork keeps the generated 8-bit forms and richer internal shading while
  preserving its source detail, binary-alpha edges, and platform-specific pixel
  budgets.
- The iPhone master is also the iPad source. Mac, Apple TV, and Apple Watch use
  separately rasterized masters so the runtime optimizer can copy every file
  without resampling.
- The source image was generated on a green chroma background. The runtime
  masters remove that background to transparency, crop to the visible
  silhouette, and then resize without palette reduction. Open bodywork, wing
  gaps, and tyre cutouts remain transparent, while the visible width is
  normalized to the established player-car footprint for each idiom.
- This directory is source provenance only. It must never be added to an Xcode
  target or copied directly into a Release product.

Do not rewrite earlier dated archives to incorporate these files. Add another
dated source archive when later runtime artwork cannot be reproduced from an
existing canonical master.
