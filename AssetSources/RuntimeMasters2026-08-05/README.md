# Runtime Masters 2026-08-05

Canonical source provenance for the experimental 32-Bit sprite family.

- `Generated/32Bit/` preserves the original flat-green ImageGen output.
- `TransparentMasters/32Bit/` preserves the soft-matte transparent cutouts.
- The player-car files with a `v1` suffix preserve its superseded first pass;
  the unsuffixed player masters contain the approved higher-detail revision.
- `CuratedCatalog/Sprites/32Bit/` contains per-platform inputs normalized to
  the established canvas sizes and optical alpha bounds. The runtime asset
  optimizer copies these inputs without further resizing.
- `PROMPTS.md` records the built-in ImageGen prompt set and normalization
  contract.

This directory is source provenance only. It must never be added to an Xcode
target or copied into a Release product.
