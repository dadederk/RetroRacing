# Font System

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Shared semantic font preferences, app-font environment, custom font registration, and Dynamic Type behavior.
- **Must not break:** Views use semantic helpers instead of hard-coded custom fonts; stored preference falls back safely; Dynamic Type remains readable; macOS navigation title exception stays intentional.
- **Key files:** `FontPreferenceStore`, `AppFontStyle`, app font environment, shared Settings/About/Paywall/Menu/Game views.

## Behavior Contract

- Font choices are user preferences, not theme definitions.
- Shared views read font settings through the environment or semantic helpers.
- The app supports the system font and the bundled retro font (`Press Start 2P`) where registered.
- If the custom font is unavailable, UI falls back to system font without crashing or clipping.
- Stored preferences must remain stable across launches and migrations.

## Usage Rules

- Use semantic font APIs for titles, labels, buttons, HUD text, and compact controls.
- Use Title 3 for the universal gameplay score and Headline for the SharePlay friend's score.
  On tvOS, preserve the same one-step hierarchy with Title and Title 2. Size each life helmet
  from its normalized visible artwork height and scale it relative to the adjacent semantic text
  style so the wider canvas and safety inset do not reduce its optical height. Keep compact
  watchOS HUD sizing appropriate for its viewing context while retaining Dynamic Type scaling.
- Do not scatter raw font names across views.
- Keep compact panels and controls sized for the longest localized string and largest supported Dynamic Type sizes.
- macOS navigation title behavior may use a platform-appropriate exception when SwiftUI navigation chrome cannot reliably apply the custom app font.

## Platform Notes

- iOS, iPadOS, macOS, tvOS, and visionOS expose the shared font preference where the Settings surface supports it.
- watchOS may use platform-appropriate defaults if the shared font preference would hurt legibility.
- Font registration belongs in composition/bootstrap code or shared helpers, not individual views.

## Accessibility

- Dynamic Type must remain functional even when the retro font is selected.
- VoiceOver labels should not include font names unless the user is explicitly editing font settings.
- Avoid all-caps or dense text where it reduces readability in localized copy.

## Testing

- Unit tests cover preference persistence, default resolution, invalid stored values, and environment propagation.
- UI/manual checks cover Settings, About, Paywall, Menu, Game HUD, Dynamic Type sizes, and custom-font fallback.

## Related

- [theming_system.md](theming_system.md) — visual themes.
- [accessibility.md](accessibility.md) — Dynamic Type and inclusive UI behavior.
