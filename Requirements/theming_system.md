# Theming System

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Shared game themes, theme selection, asset loading, road masks, monetized theme access, and platform defaults.
- **Must not break:** Shared theme logic stays platform-agnostic; platform defaults remain stable; theme access respects Unlimited Plays where premium themes are enabled.
- **Key files:** `GameTheme`, `ThemeManager`, theme assets, `GameScene` theme application, road-mask generation scripts.

## Theme Contract

- Themes define colors, typography intent, road appearance, optional road-exterior fill, finish/lap marker tint, player/rival car styling, and SpriteKit asset references through shared types.
- `ThemeManager` owns typed `ThemeID` selection persistence and available themes. Access is derived from each theme's `isPremium` flag and the current Unlimited Plays entitlement; no theme-unlock list is persisted.
- Theme selection uses shared `ThemeID` values rather than platform-specific branching while persisting the existing raw strings for compatibility.
- Missing SpriteKit car/crash textures try the requested theme asset, then the matching LCD semantic fallback (`playersCar-LCD`, `rivalsCar-LCD`, or `crash-LCD`), and return an empty texture only when both are unavailable.

## Current Themes

| Theme | Access | Notes |
|---|---|---|
| LCD | Free on iPhone/watchOS; Unlimited Plays on iPad/macOS/tvOS/visionOS | iPhone default. |
| Pocket | Free on watchOS; Unlimited Plays on iPhone/iPad/macOS/tvOS/visionOS | watchOS default. |
| Cartridge | Free on iPad/watchOS; Unlimited Plays on iPhone/macOS/tvOS/visionOS | Vivid home-console-inspired pixel style with a medium grey arcade road, lighter grey exterior field, and yellow lane lines; iPad default. |
| CRT | Free on macOS/watchOS; Unlimited Plays on iPhone/iPad/tvOS/visionOS | Early-1990s arcade style with the shared grey/yellow perspective road, grass exterior, richer pixel-art sprites, and RGB565 player-red ramp; macOS default. |
| Disc | Free/default on tvOS; Unlimited Plays on visionOS; free Debug experiment elsewhere | Late-1990s console style with dark asphalt, an electric aqua circuit palette, and a dedicated pre-rendered 32-Bit sprite family. On visionOS it changes Classic only; spatial mode uses Polygon models. |
| Polygon | Free/default on visionOS; free Debug experiment elsewhere | Late-1990s low-poly console style backed by canonical 3D models and a complete cross-platform fixed-camera sprite family. |

- Unlimited Plays is the monetization entitlement. Do not introduce a separate “premium tier” in user copy.
- When adding a theme, update the catalog, assets, Settings preview/selection behavior, tests, and any App Store screenshots that rely on theme visuals.

## Platform Defaults

- iPhone defaults to LCD unless a stored accessible user selection exists.
- The user-facing style names are Cartridge, CRT, Disc, and Polygon. Internal theme IDs, persisted raw values, type names, and asset families retain their existing 8-Bit, 16-Bit, 32-Bit, and 64-Bit identifiers for compatibility.
- iPad defaults to Cartridge unless a stored accessible user selection exists.
- macOS defaults to CRT unless a stored accessible user selection exists.
- tvOS defaults to Disc and always appends it to the shared catalog. It does not show a Disc Debug toggle because that theme cannot be disabled on tvOS.
- watchOS defaults to Pocket for everyone and allows all four themes without Unlimited Plays.
- visionOS defaults to Polygon and always includes all six themes in the gallery. Polygon is the free platform theme; Unlimited Plays unlocks selection of Pocket, LCD, Cartridge, CRT, and Disc. Disc and Polygon do not show Debug toggles on visionOS because both are permanent catalog entries there.
- In Debug builds, Settings exposes a Disc toggle on iPhone, iPad, macOS, and watchOS, plus a Polygon toggle on iPhone, iPad, macOS, watchOS, and tvOS. Enabling a toggle immediately adds the theme to the selectable catalog as a free QA theme; disabling a currently selected experiment restores the platform default. Builds without Debug UI ignore stored flags and include only the platform-required experimental entries.
- visionOS theme selection applies to Classic presentation. **Play in 3D** remains available for every Classic theme; spatial mode always uses the canonical Polygon models without changing or overwriting the saved Classic selection, which is restored on return.
- Platform-specific presentation can vary, but selection and access rules should remain shared.
- Theme selectors present established shared themes in Pocket, LCD, Cartridge, CRT order even when the platform default is not first, followed by included Disc and Polygon themes. visionOS exposes the complete six-theme gallery in that shared order.
- Settings exposes a selectable Style Gallery with one section per shared theme. Each section shows the theme's player car, rival car, player helmet, friend/rival helmet, crash sprite, and a four-color road palette: road surface, road lines, road exterior, and finish/lap marker. Preview rows provide theme-specific localized accessibility descriptions that summarize both the contents and the style's mood.
- On tvOS, the complete Style Gallery is embedded directly in the Theme category page alongside font and road-appearance settings; other platforms retain the standalone gallery destination.
- Unlimited Plays users keep the Settings theme selector and can open the Style Gallery from a disclosure row. The gallery marks the current theme with a checkmark and allows selecting accessible themes. Free users can open the gallery from the Theme row, inspect every theme, and use the gallery's top-of-list Unlimited Plays call to action to present the paywall. When a free user taps a locked non-current theme, the gallery presents the paywall instead of changing the selection. The call to action uses primary-contrast body copy rather than low-contrast footer text.
- The Cartridge detailed road uses a medium grey surface on a lighter grey exterior field. Yellow road lines and finish/lap markers keep at least 3:1 contrast with the road surface in normal and Increase Contrast modes.
- The CRT detailed road temporarily shares the Cartridge grey road surface and yellow line palette while using a grass exterior field. Its road lines and finish/lap markers keep at least 3:1 contrast with the road; theme text keeps at least 4.5:1 contrast with both road and exterior colors.
- The experimental Disc road uses dark asphalt, a deep-teal exterior, aqua lane lines, and a warm-yellow lap marker. The Polygon road uses midnight asphalt, a darker teal exterior, white lane lines, and a neon-aqua lap marker. Both themes keep at least 3:1 marker contrast with the road and at least 4.5:1 text contrast with road and exterior colors.
- Stored theme IDs remain persisted when their themes become inaccessible. The platform default is shown until Unlimited Plays becomes available again, at which point the stored selection is restored.

## Assets and Road Masks

- Theme assets live in the shared asset catalog where possible.
- Every shared car, crash, and helmet sprite family provides an explicit Apple Vision Pro asset-catalog rendition. Classic visionOS deterministically reuses each theme's curated iPad source unless that theme supplies a dedicated fixed-camera visionOS projection; this keeps asset resolution platform-native without forking the renderer or duplicating source artwork.
- Runtime theme textures ship as asset-catalog idiom variants only. Do not add flat PNG fallbacks under `RetroRacingShared/Resources`; successful requested loads and successful requested-to-fallback resolutions are cached by bundle identity and asset name, while failure of both assets is never cached.
- SpriteKit car, crash, and life textures use explicit per-platform pixel budgets instead of asset-catalog scale slots because SpriteKit sizes their nodes independently of SwiftUI point scale.
- Crash and life/helmet sprite families use shared canvas proportions, consistent subject landmarks, centered visible alpha bounds, and a small even safety inset so their perceived size and negative space remain stable when switching themes; each theme retains its own palette, natural silhouette width, and pixel-art treatment. Non-watch helmets use a `256×222` canvas with `210px` of visible height and `6px` top/bottom insets; Watch helmets use `64×55`, `53px`, and `1px`. Normalize height without stretching a helmet horizontally. The asset audit enforces manifest dimensions/pixel ceilings; alpha bounds, transparent corners, and natural silhouette remain visual-review requirements. HUD sizing compensates for the safety inset so the visible artwork, rather than the canvas, matches the adjacent score height.
- Player and rival car sprites keep their theme treatments while using centered visible alpha bounds and a small, even safety inset around the artwork. New theme families are normalized per idiom to the median optical footprint of the established themes so theme changes preserve perceived sprite size; when existing artwork conflicts, preserve LCD first, then Pocket, then 8-Bit, then 16-Bit.
- The player identity uses the theme-colored helmet with its light `X` in the lives HUD, and consumed HUD helmets add a primary-contrast outline while preserving their faded alpha. Friend marker backings use black; game-over social rings use a primary-contrast ring so both remain visible against their respective surfaces. The rear-facing driver helmet carries the matching `X` in every player-car idiom for solo and SharePlay gameplay.
- The 8-Bit player car uses a crisp chroma-key-derived transparent cutout, stepped diagonals, and hard binary-alpha edges while preserving the generated artwork's internal shading. Its visible width is normalized to the established per-idiom player-car footprint after cropping away the chroma background; its rear mechanics and tire treatment remain chunkier than the richer 16-Bit family while preserving the red player identity, exposed-wheel silhouette, rear wing, and light helmet `X`.
- Every theme provides an unmarked friend-life helmet using that theme's rival-driver palette. SharePlay visuals belong to the viewer's locally selected theme; missing friend art falls back to the player-life helmet and then `life-LCD` without changing synchronized match state. `life-LCD` is also the HUD default.
- Each 16-Bit sprite family provides explicit iPhone, iPad, Mac, Apple Watch, Apple TV, and Apple Vision Pro variants. All variants retain hard binary-alpha pixel edges; the asset audit enforces required idioms and pixel ceilings, while centered visible bounds and family-specific optical footprint remain visual-review requirements. The player and life sprites use RGB565-representable highlights, signature mid-tone, and shadows around the exact `R31/G11/B10` player red.
- The 16-Bit rival keeps the player's sturdy exposed-wheel rear-view family silhouette while using a cyan body, twin vertical tail-light stacks, and exactly four exhaust pipes. Its crash sprite includes one readable detached wheel, and its life helmet continues the light side-`X` marking used by the other pixel themes.
- Every 32-Bit sprite family provides explicit iPhone, iPad, Mac, Apple Watch, Apple TV, and Apple Vision Pro variants. The visionOS renditions are deterministic derivatives of the curated iPad masters. The pre-rendered artwork uses antialiased transparent edges, a bounded 256-color palette with subtle dithering, richer tonal gradients, and glossy material detail while preserving the established per-platform canvas sizes, centered alpha bounds, and optical footprints.
- The 32-Bit player car and life helmet use a magenta-red shell with a warm-ivory `X`; the cyan rival car remains unmarked and keeps exactly four exhaust pipes. The crash sprite uses opaque angular flame and debris forms with one readable detached wheel.
- Every 64-Bit sprite family provides explicit iPhone, iPad, Mac, Apple Watch, Apple TV, and Apple Vision Pro variants. The visionOS player and rival cars use their dedicated model projections; crash and helmet renditions are deterministic derivatives of the curated iPad masters. The low-poly player/rival cars, player/friend helmets, and explosive crash use antialiased transparent edges, a bounded 256-color palette with subtle dithering, normalized per-platform canvases, centered alpha bounds, and the same optical-footprint rules as the established themes.
- The 64-Bit player car and life helmet use a faceted red shell with a warm `X`; the cyan rival car and friend helmet remain unmarked. The rival car uses one vertical two-lamp stack on each side and exactly four large exhaust pipes in two symmetric pairs, carrying the established 16-Bit/32-Bit rival identity into the low-poly style. The crash uses angular orange, red, and cyan fragments with one readable detached wheel.
- The 64-Bit rival car's canonical artwork is its dedicated boxed USDA composition. The visionOS USDZ and fixed-camera sprite are generated from that model, and the five shared-platform rival renditions are deterministic derivatives of the model render; superseded ImageGen concepts are provenance only.
- Road lap-strip masks are generated by the Scripts workflow with explicit iPhone, iPad, Mac, Apple Watch, Apple TV, and Apple Vision Pro renditions and must not be hand-edited. Lane masks are obsolete and must not be reintroduced without a new rendering contract.
- Full-resolution superseded runtime art belongs under non-target `AssetSources/`; it must not be placed in app or shared target roots.
- Verify tracked generated masks without rewriting:

```bash
swift run --package-path Scripts generate-road-dash-masks --check
./retrorapid assets audit --check
```

## Accessibility

- Themes must preserve readable contrast for HUD, lane markers, cars, and overlays.
- Reduce Motion and high-contrast settings must continue to apply above theme styling.
- Big Cars and simplified road settings may alter marker rendering; see [road_markers.md](road_markers.md).

## Testing

- Unit tests cover typed catalog ordering/uniqueness, platform defaults and toggle visibility, experimental catalog insertion/removal, raw-string persistence, entitlement revocation/restoration, legacy unlock-key cleanup, invalid stored IDs, sprite-family decoding, and requested/LCD texture fallback.
- Visual/manual checks cover Settings preview with and without Unlimited Plays, normal and grayscale gameplay, Increase Contrast, road mask rendering, light/dark appearance, and screenshot-capture fixtures.

## Related

- [monetization.md](monetization.md) — Unlimited Plays entitlement.
- [road_markers.md](road_markers.md) — lane and lap marker rendering.
- [font_system.md](font_system.md) — semantic font preferences.
