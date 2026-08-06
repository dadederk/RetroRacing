# Asset Sources

Non-target source provenance for runtime artwork. Nothing in this tree may be
added to Xcode project membership or embedded in an app product.

## Archives

- `RuntimeFootprint2026-08-02/` is an immutable historical snapshot. Preserve
  every byte, including `optimize-runtime-assets.mjs`; the JavaScript is inert
  provenance and is not supported automation.
- `RuntimeMasters2026-08-03/` contains canonical per-platform masters for art
  revised after that snapshot. Its local README describes why those renditions
  are intentionally copied without resampling.
- `RuntimeMasters2026-08-04/` contains the revised 8-Bit player-car masters.
  They retain the generated artwork's internal shading and coarse pixel forms,
  with a transparent cutout and binary alpha at each platform's runtime pixel
  budget.
- `RuntimeMasters2026-08-05/` contains the generated and transparent master
  artwork for the experimental 32-Bit theme, plus curated per-platform inputs
  normalized to the established sprite canvases and optical bounds.
- `RuntimeMasters2026-08-06/` contains generated and model-derived transparent
  64-Bit masters, including superseded rival concepts, the canonical rival's
  model-derived visionOS projection, and the curated five-family
  per-platform inputs used by the active deterministic runtime-asset optimizer.
- `VisionOS64BitPrototype2026-08-05/` contains the canonical low-poly
  player USDA, dedicated boxed rival USDA composition, production manifest,
  fixed-camera sprite inputs, and review previews for the 64-Bit visionOS
  candidate. The source archive remains
  outside Xcode target membership; only outputs derived by
  `./retrorapid assets spatial` may ship. Physical-device art approval remains
  required before the candidate gate can pass.

Use `./retrorapid assets optimize` for established runtime sprite families and
`./retrorapid assets spatial` for both visionOS car models and the model-derived
rival projections. Both commands support `--dry-run` and non-mutating `--check`
modes.

When adding or revising a focused asset family, keep the resulting optimized
diff scoped to that family. If the optimizer reports unrelated generated
changes, treat them as existing drift to investigate separately instead of
including them with the new asset work.

When an existing immutable snapshot cannot reproduce approved art, add a new
dated master archive. Never rewrite a historical snapshot to make a check pass.
