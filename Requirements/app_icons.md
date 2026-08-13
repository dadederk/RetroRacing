# Alternate App Icons

## Agent summary

> Narrow tasks may stop here; open the related contracts for entitlement, localization, or asset work.

- **Scope:** iPhone/iPad alternate-icon catalog, Debug rollout flag, Unlimited Plays access, gallery behavior, Icon Composer packages, and system integration.
- **Must not break:** Classic remains the primary `nil` icon; system names are permanent; Release hides all feature UI and copy; disabling the flag never changes the installed icon.
- **Key files:** `AppIconCatalog`, `AppIconService`, `AppIconGalleryView`, `UIApplicationAppIconChanger`, `RetroRacingUniversal/Assets/RetroRapid*.icon`.

## Catalog and compatibility

| Group | Icon | System name |
|---|---|---|
| Classic | Classic | Primary icon, `nil` |
| Themes | Pocket | `RetroRapidPocket` |
| Themes | LCD | `RetroRapidLCD` |
| Themes | Cartridge | `RetroRapidCartridge` |
| Themes | CRT | `RetroRapidCRT` |
| Themes | Disc | `RetroRapidDisc` |
| Themes | Polygon | `RetroRapidPolygon` |
| Special Editions | Retro Cartridge | `RetroRapidGameCartridge` |
| Special Editions | Retro Video Game | `RetroRapidVideoGame` |

- Catalog order, IDs, package names, and non-`nil` system names are compatibility data and must not change after release.
- Classic uses `RetroRapid.icon`; its Default presentation remains visually equivalent to the shipped icon.
- Icon choice is independent from gameplay Style. Neither selection changes the other.
- The operating system's `alternateIconName` is authoritative; no duplicate selected-icon preference is stored.

## Platform and rollout

- The gallery is available when both the injected platform configuration enables it and the rollout flag is enabled. iPhone and iPad enable the platform configuration; macOS, watchOS, tvOS, and native visionOS disable it.
- UIKit system capability remains separate observable service state. It is refreshed after app activation and when Settings appears, but a transient or environment-specific `supportsAlternateIcons == false` does not hide the iPhone/iPad gallery or Debug toggle. It does reject an attempted system change with localized recovery copy.
- iPhone and iPad inject `UIApplicationAppIconChanger`. macOS, watchOS, tvOS, and native visionOS inject `UnsupportedAppIconChanger` or omit the shared surface. Platform decisions belong in composition roots, not shared views or service compile conditions.
- `DebugGameplayStorageKeys.alternateAppIconsEnabled` defaults on in Debug and respects its stored Debug override through one injected feature-flag dependency shared by the composition root, service, and Debug toggle.
- Builds without Debug features always resolve the flag to false, even if a prior Debug build stored true.
- Debug Settings shows **Enable alternate app icons** on configured iPhone/iPad builds even when the current environment reports that icon changes are unsupported.
- Alternate packages and generated `CFBundleAlternateIcons` declarations remain in Debug and Release products. Release hides the Settings row, gallery, Debug toggle, and icon-specific paywall benefit.
- Turning the flag off hides feature surfaces immediately but does not reset an installed alternate or call the system API.

## Access and selection

- Classic is always selectable and passes `nil` to the platform adapter.
- All eight alternates require Unlimited Plays.
- Cached returning-purchaser access permits selection while the first entitlement refresh is unresolved.
- Without cached access, unresolved alternates remain visible and disabled; no paywall is presented until resolution.
- A resolved free user can inspect every icon. Selecting a locked alternate opens the voluntary Unlimited Plays paywall.
- After entitlement revocation, an installed alternate remains selected. Classic stays available; other alternate changes remain locked.
- Selecting the current icon is a no-op. While a system request is active, repeated changes are rejected.
- After success, refresh from `alternateIconName` and rely on Apple's confirmation. On failure, preserve the system selection and show localized recovery copy.

## Gallery and accessibility

- Settings places an **App Icon** disclosure row inside Theme, directly after the Style controls, when the gallery is available. It does not duplicate the entry in a standalone section.
- The gallery mirrors the Style Gallery with a native `List` and ordered Classic, Themes, and Special Editions sections. Each option is a full-width preview button; accessibility Dynamic Type sizes switch its preview and label to a vertical layout.
- Resolved free users see the same top-of-list Unlimited Plays prompt used by the Style Gallery. They can inspect every option, and selecting a locked alternate presents the voluntary paywall. Unlimited Plays users select alternates directly.
- Default preview exports are neutral references; the gallery does not add explanatory appearance copy above the choices.
- Every icon is one semantic `Button` with a localized name, visual description, selected/locked/changing state, and a non-color state indicator.
- Preserve reading and focus order for VoiceOver, Voice Control, Switch Control, and Full Keyboard Access. Support Dynamic Type, Increase Contrast, and Differentiate Without Color.

## Icon Composer assets

- Keep every source unmasked and `1024×1024`; the system applies the icon mask.
- Each `.icon` package has no more than four groups and references only package-local layer assets.
- Default artwork remains recognizable in Dark, Mono, Clear Light/Dark, and Tinted Light/Dark. Tune Composer material parameters without swapping subjects or composition.
- Pixel artwork keeps hard edges and minimal glass. Higher-resolution cars may use restrained depth. Special Editions may use slightly stronger shell material while keeping screen/label content dense.
- Gallery previews are `512×512` ordinary image assets exported from the Default package source.
- `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` declares all eight alternates for Universal Debug and Release; Xcode generates Info.plist entries.

## Testing

- Shared tests cover catalog order/uniqueness, stable mappings, policy states, flag isolation, success/failure/refresh, unsupported and disabled requests, and repeated-tap suppression.
- The asset audit verifies packages, source dimensions, layer references, previews, build-setting declarations, and shared catalog mappings. Full Release audit also verifies generated `CFBundleAlternateIcons`.
- Manual iPhone/iPad QA covers every icon and return to Classic, entitlement states, relaunch persistence, system surfaces, all adaptive appearances, representative wallpapers/tints, Dynamic Type, and assistive technologies.

## Related

- [monetization.md](monetization.md) — Unlimited Plays access.
- [debug_simulation.md](debug_simulation.md) — production isolation.
- [accessibility.md](accessibility.md) · [localization.md](localization.md) · [testing.md](testing.md)
