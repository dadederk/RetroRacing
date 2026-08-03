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

Use `./retrorapid assets optimize` for all active generation. Default execution
applies the plan, `--dry-run` prints it, and `--check` renders to temporary
storage before comparing pixels and semantic catalog JSON.

When an existing immutable snapshot cannot reproduce approved art, add a new
dated master archive. Never rewrite a historical snapshot to make a check pass.
