# Discarded Asset Archive

Rejected artwork retained for provenance and future visual reference. This
directory is outside every Xcode target and must never appear in Release
products.

The 2026-08-03 curation reviewed the LCD, Pocket, and 8-Bit player/rival
families using decoded, alpha-trimmed pixel comparisons. No identical artwork
remained after metadata cleanup, so the retained files represent distinct
palette, silhouette, detail, or perspective decisions. The audit rejects any
future decoded duplicate group and reports the largest-pixel canonical file to
retain.

Rules:

- Do not add `.DS_Store` or other filesystem metadata.
- Keep the largest-pixel file when decoded, alpha-trimmed artwork is identical.
- Preserve genuinely distinct palette, silhouette, perspective, and detail
  variants even when filenames belong to the same family.
- Do not use this archive as an optimizer source; approved masters belong in a
  dated `AssetSources/` archive.
