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
| LCD | Free on iPhone/watchOS; Unlimited Plays on iPad/macOS/tvOS | iPhone default. |
| Pocket | Free on watchOS; Unlimited Plays on iPhone/iPad/macOS/tvOS | watchOS default. |
| 8-Bit | Free on iPad/watchOS; Unlimited Plays on iPhone/macOS/tvOS | Vivid home-console-inspired pixel style with a medium grey arcade road, lighter grey exterior field, and yellow lane lines; iPad default. |
| 16-Bit | Free on macOS/tvOS/watchOS; Unlimited Plays on iPhone/iPad | Early-1990s arcade style with the shared grey/yellow perspective road, grass exterior, richer pixel-art sprites, and RGB565 player-red ramp; macOS/tvOS default. |

- Unlimited Plays is the monetization entitlement. Do not introduce a separate “premium tier” in user copy.
- When adding a theme, update the catalog, assets, Settings preview/selection behavior, tests, and any App Store screenshots that rely on theme visuals.

## Platform Defaults

- iPhone defaults to LCD unless a stored accessible user selection exists.
- iPad defaults to 8-Bit unless a stored accessible user selection exists.
- macOS and tvOS default to 16-Bit unless a stored accessible user selection exists.
- watchOS defaults to Pocket for everyone and allows all four themes without Unlimited Plays.
- visionOS remains a placeholder and does not expose gameplay theme selection.
- Platform-specific presentation can vary, but selection and access rules should remain shared.
- Theme selectors present shared themes in Pocket, LCD, 8-Bit, 16-Bit order even when the platform default is not first.
- Settings exposes a selectable Style Gallery with one section per shared theme. Each section shows the theme's player car, rival car, player helmet, friend/rival helmet, crash sprite, and a four-color road palette: road surface, road lines, road exterior, and finish/lap marker. Preview rows provide theme-specific localized accessibility descriptions that summarize both the contents and the style's mood.
- Unlimited Plays users keep the Settings theme selector and can open the Style Gallery from a disclosure row. The gallery marks the current theme with a checkmark and allows selecting accessible themes. Free users can open the gallery from the Theme row, inspect every theme, and use the gallery's top-of-list Unlimited Plays call to action to present the paywall. When a free user taps a locked non-current theme, the gallery presents the paywall instead of changing the selection. The call to action uses primary-contrast body copy rather than low-contrast footer text.
- The 8-Bit detailed road uses a medium grey surface on a lighter grey exterior field. Yellow road lines and finish/lap markers keep at least 3:1 contrast with the road surface in normal and Increase Contrast modes.
- The 16-Bit detailed road temporarily shares the 8-Bit grey road surface and yellow line palette while using a grass exterior field. Its road lines and finish/lap markers keep at least 3:1 contrast with the road; theme text keeps at least 4.5:1 contrast with both road and exterior colors.
- Stored theme IDs remain persisted when their themes become inaccessible. The platform default is shown until Unlimited Plays becomes available again, at which point the stored selection is restored.

## Assets and Road Masks

- Theme assets live in the shared asset catalog where possible.
- Runtime theme textures ship as asset-catalog idiom variants only. Do not add flat PNG fallbacks under `RetroRacingShared/Resources`; successful requested loads and successful requested-to-fallback resolutions are cached by bundle identity and asset name, while failure of both assets is never cached.
- SpriteKit car, crash, and life textures use explicit per-platform pixel budgets instead of asset-catalog scale slots because SpriteKit sizes their nodes independently of SwiftUI point scale.
- Crash and life/helmet sprite families use shared canvas proportions, consistent subject landmarks, centered visible alpha bounds, and a small even safety inset so their perceived size and negative space remain stable when switching themes; each theme retains its own palette, natural silhouette width, and pixel-art treatment. Non-watch helmets use a `256×222` canvas with `210px` of visible height and `6px` top/bottom insets; Watch helmets use `64×55`, `53px`, and `1px`. Normalize height without stretching a helmet horizontally. The asset audit enforces manifest dimensions/pixel ceilings; alpha bounds, transparent corners, and natural silhouette remain visual-review requirements. HUD sizing compensates for the safety inset so the visible artwork, rather than the canvas, matches the adjacent score height.
- Player and rival car sprites keep their theme treatments while using centered visible alpha bounds and a small, even safety inset around the artwork. New theme families are normalized per idiom to the median optical footprint of the established themes so theme changes preserve perceived sprite size; when existing artwork conflicts, preserve LCD first, then Pocket, then 8-Bit, then 16-Bit.
- The player identity uses the theme-colored helmet with its light `X` in the lives HUD, and the rear-facing driver helmet carries the matching `X` in every player-car idiom for solo and SharePlay gameplay.
- Every theme provides an unmarked friend-life helmet using that theme's rival-driver palette. SharePlay visuals belong to the viewer's locally selected theme; missing friend art falls back to the player-life helmet and then `life-LCD` without changing synchronized match state. `life-LCD` is also the HUD default.
- Each 16-Bit sprite family provides explicit iPhone, iPad, Mac, Apple Watch, and Apple TV variants. All variants retain hard binary-alpha pixel edges; the asset audit enforces required idioms and pixel ceilings, while centered visible bounds and family-specific optical footprint remain visual-review requirements. The player and life sprites use RGB565-representable highlights, signature mid-tone, and shadows around the exact `R31/G11/B10` player red.
- The 16-Bit rival keeps the player's sturdy exposed-wheel rear-view family silhouette while using a cyan body, twin vertical tail-light stacks, and exactly four exhaust pipes. Its crash sprite includes one readable detached wheel, and its life helmet continues the light side-`X` marking used by the other pixel themes.
- Road lap-strip masks are generated by the Scripts workflow and must not be hand-edited. Lane masks are obsolete and must not be reintroduced without a new rendering contract.
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

- Unit tests cover typed catalog ordering/uniqueness, platform defaults, raw-string persistence, entitlement revocation/restoration, legacy unlock-key cleanup, invalid stored IDs, and requested/LCD texture fallback.
- Visual/manual checks cover Settings preview with and without Unlimited Plays, normal and grayscale gameplay, Increase Contrast, road mask rendering, light/dark appearance, and screenshot-capture fixtures.

## Related

- [monetization.md](monetization.md) — Unlimited Plays entitlement.
- [road_markers.md](road_markers.md) — lane and lap marker rendering.
- [font_system.md](font_system.md) — semantic font preferences.
