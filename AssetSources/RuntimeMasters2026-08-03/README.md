# Runtime Masters 2026-08-03

Canonical runtime inputs for artwork revised after the immutable
`RuntimeFootprint2026-08-02` archive was captured.

- The player-car files intentionally preserve per-platform rasterization. They
  are copied without resampling by `./retrorapid assets optimize`.
- The life files preserve the later Watch-specific rasterization; other life
  variants continue to come from the historical footprint.
- `CuratedCatalog/` preserves exact approved per-platform inputs for the
  16-Bit and friend-helmet families introduced after the historical snapshot.
- This directory is source provenance only. It must never be added to an Xcode
  target or copied into a Release product.

Do not rewrite the historical footprint to incorporate these files. Add a new
dated source archive when later runtime artwork cannot be reproduced from an
existing canonical master.
