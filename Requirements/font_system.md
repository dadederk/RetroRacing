# Font System

## Overview

RetroRacing provides a customizable font system that allows users to choose between a retro pixel font and system fonts. The font preference applies globally across all UI text, respecting the user's choice throughout the app.

## Font Architecture

### FontPreferenceStore

The `FontPreferenceStore` is an `@Observable` class that manages font preferences:

```swift
@Observable
@MainActor
public final class FontPreferenceStore {
    public var currentStyle: AppFontStyle
    public let isCustomFontAvailable: Bool
    
    public func font(textStyle: Font.TextStyle) -> Font
    public func font(fixedSize: CGFloat) -> Font
}
```

**Key Features:**
- Persists user's font choice in `UserDefaults`
- Detects if custom font is available on the device
- Exposes semantic (`textStyle`) and fixed-size font APIs

### AppFontStyle Enum

```swift
public enum AppFontStyle: String, CaseIterable {
    case custom = "custom"              // "Press Start 2P" retro pixel font
    case system = "system"              // Standard system font
    case systemMonospaced = "systemMonospaced" // System monospaced font
}
```

### Environment Integration

The font preference store is injected into the SwiftUI environment, making it accessible to all descendant views:

```swift
extension EnvironmentValues {
    public var fontPreferenceStore: FontPreferenceStore?
}

extension View {
    public func fontPreferenceStore(_ store: FontPreferenceStore?) -> some View
}
```

## Semantic Font Helpers

`FontPreferenceStore` provides convenience properties for common semantic font sizes:

- `captionFont` - Size 12 (small supplementary text)
- `caption2Font` - Size 11 (extra small supplementary text)
- `subheadlineFont` - Size 15 (secondary text)
- `headlineFont` - Size 17 (emphasis text)
- `bodyFont` - Size 17 (body text)
- `titleFont` - Size 28 (large titles)

These map to Dynamic-Type-aware semantic text styles.

## Implementation Pattern

### 1. Environment Access

Views access the font preference store via the environment:

```swift
struct MyView: View {
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore
    
    var body: some View {
        Text("Hello")
            .font(fontPreferenceStore?.font(textStyle: .body) ?? .body)
    }
}
```

### 2. Fallback Pattern

Always provide a fallback when the environment value might be `nil`:

```swift
.font(fontPreferenceStore?.font(textStyle: .caption) ?? .caption)
```

This ensures views render correctly even if the font preference store hasn't been injected.

### 3. Environment Injection

Root views inject the store into the environment:

```swift
MenuView(...)
    .fontPreferenceStore(fontPreferenceStore)
```

## Platform Support

### iOS/iPadOS/macOS/tvOS

- Full support for all three font styles
- "Press Start 2P" custom font is bundled with the app
- Font preference persists across launches
- Settings screen provides font picker (if custom font is available)

### watchOS

- Same font options as other platforms
- Smaller base font sizes for watch display
- Font picker integrated into watchOS settings

## Custom Font: Press Start 2P

**About:**
- Retro pixel font inspired by classic 8-bit games
- Licensed under Open Font License (OFL)
- Registered at app launch via `AppBootstrap.registerCustomFont()`
- Source: [Google Fonts - Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P)

**Fallback:**
- If custom font fails to load, `isCustomFontAvailable` is `false`
- Font picker section is hidden in Settings
- System automatically falls back to `.system` style

## Views Using Font Preferences

All user-facing text respects the font preference:

### Settings Screen
- All labels, headers, footers
- Section headers
- Picker options
- Toggle labels
- Done/actions buttons in Settings and nested tutorial sheets
- On macOS, long Settings helper/footer copy is rendered as inline section rows (instead of native `Section` footers) to avoid footer height clipping while preserving configured font usage.

### About Screen
- Footer text
- Link titles and subtitles
- Section headers

### Paywall View
- Header title and caption
- Product information
- Info card titles and bodies
- Error messages
- Footer disclaimers

### Menu & Game Views
- Buttons
- HUD elements (score, lives)
- Pause/resume labels
- Game HUD/chrome uses `font(fixedSize:)` to preserve pixel-locked styling where required.
- Game-over content rows and action buttons use semantic fonts from `FontPreferenceStore`.
- Game-over action labels (`Restart`, `Finish`) apply semantic fonts directly on `Text` labels so custom button styles do not override configured typography.

### macOS Navigation Title Exception

- On macOS, native window/navigation titles remain system-rendered to preserve platform conventions.
- The configured app font still applies to actionable/control text (buttons, picker labels/options, section content, and tutorial option buttons).

## Testing

### FontPreferenceStoreTests

Unit tests verify:
- Initial style defaults to `custom` when no stored value
- Style changes persist to UserDefaults
- When custom font unavailable, stored `.custom` falls back to `.system`
- Semantic custom size mapping matches legacy typography baselines

### Manual Testing

1. Launch app with default settings (custom font)
2. Navigate through all screens - verify consistent font
3. Change to system font in Settings
4. Navigate through all screens - verify system font everywhere
5. Change to system monospaced
6. Verify monospaced font applies globally

## Accessibility Considerations

### Dynamic Type

- Flowing text uses semantic APIs (`font(textStyle:)`) so system and monospaced styles follow native Dynamic Type behavior.
- Custom font uses `Font.custom(_:size:relativeTo:)` internally, with a documented base-size mapping per text style (`caption2` 11, `caption` 12, `subheadline` 15, `body/headline` 17, `title` 28, plus standard values for other styles).
- Pixel-locked gameplay typography (HUD/chrome) uses `font(fixedSize:)`.

### VoiceOver

Font choice does not affect VoiceOver - all text remains accessible regardless of font style.

## Implementation Details

### Font Registration

The custom font is registered at app launch:

```swift
// AppBootstrap.swift
static func registerCustomFont() -> Bool {
    FontRegistrar.registerPressStart2P()
}
```

### Environment Setup

Each platform's app entry point creates a `FontPreferenceStore` and injects it:

```swift
// RetroRacingApp.swift
private let fontPreferenceStore: FontPreferenceStore

init() {
    let customFontAvailable = AppBootstrap.registerCustomFont()
    fontPreferenceStore = FontPreferenceStore(
        userDefaults: userDefaults,
        customFontAvailable: customFontAvailable
    )
}

var body: some Scene {
    WindowGroup {
        NavigationStack {
            rootView
        }
        .fontPreferenceStore(fontPreferenceStore) // Injected here
    }
}
```

### Storage Key

Font preference is stored in UserDefaults under key `"selectedFontStyle"`.

## Performance Considerations

### Font Caching

SwiftUI automatically caches font objects. Creating fonts via `FontPreferenceStore.font(textStyle:)` and `FontPreferenceStore.font(fixedSize:)` is lightweight and can be called in view bodies.

### Memory

Font preference store is a lightweight object (~100 bytes). One instance per app is sufficient.

## Migration & Compatibility

### First Launch

If no font preference is stored, defaults to `.custom` (retro font) to match the game's aesthetic.

### Future Fonts

Additional fonts can be added by:
1. Adding new cases to `AppFontStyle`
2. Updating `semanticFont(for:textStyle:)` and `fixedFont(for:size:)` switch statements
3. Registering fonts in `AppBootstrap`
4. Adding localized strings for font names

## Known Limitations

1. **Custom font required** - If "Press Start 2P" fails to load, the app falls back to system fonts gracefully
2. **No per-view overrides** - Font preference is global; individual views cannot override
3. **Fixed-size gameplay typography** - Some UI elements (game HUD/chrome) intentionally use fixed sizes to preserve retro readability

## References

- [SwiftUI Font Documentation](https://developer.apple.com/documentation/swiftui/font)
- [Custom Fonts in SwiftUI](https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text)
- [Press Start 2P Font](https://fonts.google.com/specimen/Press+Start+2P)
- [Open Font License](https://scripts.sil.org/OFL)
