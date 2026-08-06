# visionOS 64-Bit Player/Rival Car Candidate Sources

Canonical source archive for the visionOS vertical-slice player and rival cars. Nothing in this archive belongs to an Xcode target; the shipping USDZ models and sprites are deterministic derived outputs.

## Result

- Original rear-engined open-wheel player car with the established red identity and warm-ivory helmet `X`.
- Explicit faceted meshes and normals rather than smooth runtime primitives.
- 65 active player components and a 63-component rival composition that reuses the boxed base geometry.
- Nine small `UsdPreviewSurface` materials with no external textures.
- RealityKit bounds of approximately `2.94 × 1.86 × 4.09` meters.
- 1,264 player triangles and 1,224 rival triangles, both below the 2,000-triangle candidate ceiling.
- Valid 27,594-byte player and 27,033-byte rival USDZ packages suitable for the visionOS `RealityView` candidate.

The models deliberately favor silhouette and palette over dense geometry. The rival composition inherits the proven player topology, bakes its cyan palette, removes the helmet `X` and single lamps, activates two stacked lamps on each side, and retains the four exhaust tubes.

## Contents

| Path | Role |
|---|---|
| `PlayerCar/player-car-64bit.usda` | Canonical editable mesh/material source. |
| `PlayerCar/spatial-production.json` | Canonical sprite-source, camera, output, hierarchy, bounds, and budget configuration. |
| `PlayerCar/player-car-64bit.usdz` | Historical review package; the shipping package is regenerated from the USDA. |
| `PlayerCar/Previews/player-car-64bit-sprite.png` | Low-resolution orthographic render enlarged with nearest-neighbor scaling to test the future 2D theme. |
| `PlayerCar/Previews/player-car-64bit-hero.png` | Three-quarter art-direction render. |
| `PlayerCar/Previews/player-car-64bit-turntable.gif` | Twelve-angle animated review. |
| `PlayerCar/Previews/player-car-64bit-turntable-contact-sheet.png` | Static all-angle review. |
| `PlayerCar/Previews/turntable-*.png` | Source frames for the animated/static turntable previews. |
| `RivalCar/rival-car-64bit.usda` | Canonical rival composition over the boxed player geometry. |
| `RivalCar/Previews/rival-car-64bit-sprite.png` | Deterministic fixed-camera render used to derive all runtime rival sprites. |

Preview PNG/GIF files are derived review artifacts. The prototype used SceneKit only as an offscreen macOS review renderer; the shipping visionOS renderer remains RealityKit.

## Vertical-Slice Production Outputs

- `./retrorapid assets spatial` composes and packages both USDA sources under `Resources/Models/`, copies the established model-derived player projection, renders the rival projection from the composed 3D model, and derives its five shared-platform sources.
- `--check` performs a byte-for-byte drift check after validating source exclusion, target membership, hierarchy/material names, bounds, RealityKit import, triangle count, and file budgets.
- The 2D rival source in `AssetSources/RuntimeMasters2026-08-06/CuratedVisionOS/` is copied from the model-derived preview; it uses paired vertical two-lamp stacks and four exhaust tubes rather than an ImageGen or hue-shifted player projection.
- Runtime Tabletop rivals clone the dedicated rival USDZ directly. No runtime recoloring or mesh-visibility mutation is used to manufacture rival identity.
- This source and its fixed camera/source configuration are canonical for the candidate. Physical Vision Pro review still decides final art approval.

## Validation

```bash
./retrorapid assets spatial --dry-run
./retrorapid assets spatial --check
```

The workflow checks both composed USD stages with Apple USD tooling and loads both generated packages through `Entity(contentsOf:)`. It also enforces a 100 KB ceiling per USDZ and a 25 KB ceiling for each visionOS sprite.

## Remaining Candidate Approval

- Review scale, materials, and lighting on a physical Vision Pro.
- Approve the rear wing height, wheel proportions, body palette, gameplay-scale player helmet `X`, rival light stacks, and four-exhaust read.
- Verify player/rival 2D correspondence and silhouette at the Classic board's supported window sizes.
- Record physical-device accessibility, comfort, frame pacing, and memory evidence in the existing visionOS spatial plan.
- Stable animation anchors, collision proxies, a lower-detail variant, and the remaining 64-Bit model family are deferred beyond this vertical-slice gate.
