# Font System

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Shared semantic font preferences, app-font environment, custom font registration, and Dynamic Type behavior.
- **Must not break:** Press Start 2P remains the clean-install default and persisted `custom` value; unavailable selections stay stored while System renders; all SwiftUI text scales through Accessibility 5; the macOS navigation-title exception stays intentional.
- **Key files:** `AppFontStyle`, `AppTypography`, `AppFontResolver`, `AppFontRegistry`, `FontPreferenceStore`, `FontSelectionView`, and shared Settings/About/Menu/Game views.

## Behavior Contract

- Font choices are user preferences, not theme definitions.
- Shared views read font settings through the environment or semantic helpers.
- Settings always exposes this ordered catalog: Press Start 2P, System, System Monospaced,
  OpenDyslexic, Atkinson Hyperlegible, and Lexend.
- Press Start 2P remains the clean-install default and keeps raw persisted identifier `custom`.
  The storage key remains `selectedFontStyle`; existing System and System Monospaced values remain valid.
- `FontPreferenceStore.currentStyle` is the requested selection. `effectiveStyle` is System only
  while a requested bundled family has no registered face. The requested raw value is never
  overwritten by fallback, so a later launch restores it automatically when the resources return.
- System and System Monospaced are always available. A bundled family is available when at least
  one authoritative PostScript face is registered.

## Usage Rules

- SwiftUI presentation reads the non-optional `appTypography` environment value. Direct
  `FontPreferenceStore` access is limited to Settings and composition roots.
- Use `appFont(_:weightTier:)` for semantic text and
  `appFont(scaledSize:relativeTo:weightTier:)` only for oversized typography whose input size has
  already been scaled with `@ScaledMetric`.
- `AppFontResolver` derives the platform-native Large-category baseline for every
  `Font.TextStyle`, uses `Font.custom(_:size:relativeTo:)`, preserves semantic weights such as
  Headline semibold, and maps explicit weight tiers consistently across families.
- Bold Text promotes a custom face to the next bundled weight where available. Missing requested
  weights resolve to the nearest registered face; a family with no face falls back to the same
  semantic System role and requested weight.
- Use Title 1 for the universal gameplay score and Title 2 for the SharePlay friend's score.
  On tvOS, preserve the same Title 1 and Title 2 hierarchy. Size each life helmet
  from its normalized visible artwork height and scale it relative to the adjacent semantic text
  style so the wider canvas and safety inset do not reduce its optical height. Keep compact
  watchOS HUD sizing appropriate for its viewing context while retaining Dynamic Type scaling.
- Do not scatter raw PostScript names or construct selected fonts in views. Concrete `Font` values
  are not view input-model fields; inputs carry semantic text styles and weight tiers.
- Menus use semantic Title 1 for the standalone RetroRapid title and Headline and Footnote roles
  for supporting content, and always have a scroll container. The title renders through
  `BrandMark.text`, which requests an italic `!` when the selected font supports it. There is no
  Dynamic Type cap or fixed per-platform menu font size.
- Pause and gameplay controls use Headline/Callout roles. The countdown keeps a 72-point Large
  Title-relative baseline via `@ScaledMetric` and the scaled-size resolver.
- Keep compact panels and controls sized for the longest localized string and largest supported Dynamic Type sizes.
- macOS navigation title behavior may use a platform-appropriate exception when SwiftUI navigation chrome cannot reliably apply the custom app font.

## Platform Notes

- iOS, iPadOS, macOS, watchOS, tvOS, and visionOS expose the shared font preference using native
  list/navigation containers and shared selection-row behavior.
- `AppFontRegistry` registers all bundled faces once per process from the shared framework and app
  bundle, treats PostScript-name presence as authoritative (including `UIAppFonts` registration),
  and injects an immutable availability snapshot into the store.
- Registration logs missing files, registration outcomes, and unavailable faces through structured
  `AppLog.font` events.
- The decorative SpriteKit `Menlo-Bold` avatar initials and deliberately fixed exported share-card
  artwork remain outside the shared SwiftUI typography path.

## Accessibility

- All SwiftUI text supports Dynamic Type through Accessibility 5 for every family. Helmet artwork
  and text-linked spacing/icons scale with their adjacent semantic roles through `@ScaledMetric`.
- Accessibility sizes use full-width vertical gameplay HUD compositions and suppress compact
  landscape side rails. Repeated rows stack and adaptive grids collapse to one column where needed.
- Font rows render their family name in the candidate face, expose the selected trait, and announce
  unavailable/fallback state. Unavailable families stay visible and disabled; options are not hidden
  by locale. VoiceOver labels otherwise omit font names unless the user is editing typography.
- Representative accented Latin and CJK sample text remains available for glyph-fallback checks.
- Avoid all-caps or dense text where it reduces readability in localized copy.

## Testing

- Unit tests cover catalog order/uniqueness, face and weight mappings, semantic baselines, Bold Text
  promotion, missing-weight/family fallback, persisted/invalid values, unavailable-selection
  preservation and restoration, environment defaults, gameplay roles, and bundled-license loading.
- Layout tests cover accessibility HUD side-rail suppression and adaptive vertical/full-width policy.
- Manual checks cover every family at Large and Accessibility 5 across all six targets, plus Bold
  Text, double-length localization, accented Latin/CJK glyph fallback, and missing-resource fallback.

## Related

- [theming_system.md](theming_system.md) — visual themes.
- [accessibility.md](accessibility.md) — Dynamic Type and inclusive UI behavior.
