# Theming System

## Overview

RetroRacing features an interchangeable visual theme system that allows users to customize the game's appearance. Themes evoke different retro gaming aesthetics while maintaining accessibility and readability.

## Theme Architecture

### Theme Protocol

```swift
protocol GameTheme {
    var id: String { get }
    var name: LocalizedStringKey { get }
    var isPremium: Bool { get }
    
    // Colors
    func backgroundColor(for state: GameState) -> Color
    func gridLineColor() -> Color
    func playerCarColor() -> Color
    func rivalCarColor() -> Color
    func crashColor() -> Color
    func textColor() -> Color
    
    // Visual Style
    func cellBorderWidth() -> CGFloat
    func cornerRadius() -> CGFloat
    
    // Optional: Custom sprites
    func playerCarSprite() -> String? // Image name
    func rivalCarSprite() -> String?
    func crashSprite() -> String?
}
```

### Theme Manager

```swift
@Observable @MainActor
final class ThemeManager {
    private(set) var currentTheme: GameTheme
    private(set) var availableThemes: [GameTheme]
    private(set) var unlockedThemes: Set<String>
    
    func setTheme(_ theme: GameTheme)
    func isThemeAvailable(_ theme: GameTheme) -> Bool
    func unlockTheme(_ theme: GameTheme)
    func purchaseTheme(_ theme: GameTheme) async throws
}
```

## Default Themes

### Classic Theme (Free)

Default theme, available to all users.

**Visual Style:**
- Background: Light green (#9ADC26)
- Grid lines: Gray
- Player car: Blue
- Rival car: Red
- Simple, clean aesthetic

**Platforms:** All

### Game Boy Theme (Free)

Iconic monochrome green aesthetic.

**Visual Style:**
- Background: `#9BBC0F` (classic Game Boy green)
- Foreground: `#0F380F` (dark green)
- Player car: Dark green outline
- Rival car: Lighter green outline
- 2-bit color palette

**Best on:** watchOS (small screen, nostalgia factor)

### LCD Handheld Theme (Premium)

Inspired by 80s/90s LCD handhelds (Game & Watch style).

**Visual Style:**
- Background: Light gray with subtle grid
- Sprites: Black silhouettes
- Segmented display aesthetic
- No anti-aliasing, sharp edges

**Best on:** iOS (portrait mode, handheld feel)

### 8-Bit Theme (Premium)

Classic 8-bit console aesthetic with vibrant colors.

**Visual Style:**
- Background: Deep blue
- Sprites: Chunky pixel art with bold colors
- CRT scanline effect (optional)
- Rich color palette

**Best on:** iPadOS, macOS (larger screens)

### Neon/Synthwave Theme (Premium)

Modern retro aesthetic with neon colors.

**Visual Style:**
- Background: Dark purple/black gradient
- Grid lines: Cyan neon glow
- Player car: Pink/magenta neon
- Rival car: Cyan neon
- Glow effects

**Best on:** tvOS, visionOS (dark environments, HDR)

## Platform-Specific Recommendations

When a user first launches the app on a platform, suggest an appropriate theme:

| Platform | Suggested Theme | Reason |
|----------|-----------------|--------|
| watchOS | Game Boy | Small screen, monochrome nostalgia |
| iOS | LCD Handheld | Handheld device, portable gaming |
| iPadOS | 8-Bit | Larger screen, richer colors |
| tvOS | Neon/Synthwave | Living room, cinematic feel |
| macOS | 8-Bit or Classic | Desktop, productivity-friendly |
| visionOS | Neon/Synthwave | Immersive environment, HDR |

**Implementation:**
```swift
func suggestedTheme(for platform: Platform) -> GameTheme {
    #if os(watchOS)
    return GameBoyTheme()
    #elseif os(iOS)
    return LCDHandheldTheme()
    #elseif os(tvOS)
    return NeonTheme()
    #elseif os(macOS)
    return EightBitTheme()
    #elseif os(visionOS)
    return NeonTheme()
    #endif
}
```

## Monetization

### Free Themes
- Classic (default)
- Game Boy

### Premium Themes (In-App Purchase)

**Option 1: Individual Theme Purchases**
- LCD Handheld: $0.99
- 8-Bit: $0.99
- Neon/Synthwave: $0.99
- Bundle (all premium): $1.99 (33% savings)

**Option 2: Premium Unlock**
- Single IAP ($1.99) unlocks all current and future themes

**Recommendation:** Option 2 (simpler, better value perception)

### StoreKit Configuration

```swift
enum ThemeProduct: String, CaseIterable {
    case premiumThemes = "com.retroRacing.premiumThemes"
    
    var displayName: LocalizedStringKey {
        switch self {
        case .premiumThemes: return "Premium Themes Pack"
        }
    }
}
```

## Theme Selection UI

### Settings View

```swift
struct ThemeSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        List {
            Section("Free Themes") {
                ForEach(freeThemes) { theme in
                    ThemeRow(theme: theme)
                }
            }
            
            Section("Premium Themes") {
                ForEach(premiumThemes) { theme in
                    ThemeRow(theme: theme)
                }
                
                if !themeManager.hasPremiumUnlock {
                    Button("Unlock All Themes - $1.99") {
                        // Purchase flow
                    }
                }
            }
        }
    }
}
```

### Theme Preview

Show live preview of theme applied to a mini game grid:

```swift
struct ThemePreview: View {
    let theme: GameTheme
    
    var body: some View {
        // Mini 3x3 grid with theme applied
        GameGridPreview(theme: theme)
            .frame(width: 120, height: 120)
    }
}
```

## Accessibility Considerations

### High Contrast Mode

When `UIAccessibility.isDarkerSystemColorsEnabled` or similar:
- Increase contrast between background and sprites
- Use bold outlines on sprites
- Override theme colors for readability

```swift
func playerCarColor() -> Color {
    if UIAccessibility.isDarkerSystemColorsEnabled {
        return .black // High contrast override
    }
    return theme.playerCarColor()
}
```

### Color Blindness Support

- Ensure player vs rival distinction isn't color-only
- Use shapes/patterns in addition to colors
- Test with color blindness simulators

### Reduce Motion

- Disable CRT scanline effects
- Remove glow animations
- Keep theme transitions instant

## Implementation Details

### Theme Storage

Store selected theme in `UserDefaults`:

```swift
@AppStorage("selectedThemeID") private var selectedThemeID: String = "classic"
```

### Theme Application

Theme is applied at the `GameScene` level:

```swift
class GameScene: SKScene {
    var theme: GameTheme = ClassicTheme() {
        didSet {
            applyTheme()
        }
    }
    
    private func applyTheme() {
        backgroundColor = UIColor(theme.backgroundColor(for: gameState))
        // Update sprite colors, grid lines, etc.
    }
}
```

### Theme Unlocking

```swift
struct ThemeUnlockStorage {
    private let key = "unlockedThemes"
    
    func isUnlocked(_ themeID: String) -> Bool {
        let unlocked = UserDefaults.standard.stringArray(forKey: key) ?? []
        return unlocked.contains(themeID)
    }
    
    func unlock(_ themeID: String) {
        var unlocked = UserDefaults.standard.stringArray(forKey: key) ?? []
        if !unlocked.contains(themeID) {
            unlocked.append(themeID)
            UserDefaults.standard.set(unlocked, forKey: key)
        }
    }
}
```

## Testing Strategy

### Unit Tests

```swift
func testThemeColors() {
    let theme = GameBoyTheme()
    let state = GameState()
    
    let bgColor = theme.backgroundColor(for: state)
    XCTAssertEqual(bgColor, Color(red: 0.608, green: 0.737, blue: 0.059))
}

func testThemeUnlocking() {
    let storage = ThemeUnlockStorage()
    XCTAssertFalse(storage.isUnlocked("lcd"))
    
    storage.unlock("lcd")
    XCTAssertTrue(storage.isUnlocked("lcd"))
}

func testPremiumThemeRequiresPurchase() {
    let manager = ThemeManager()
    let theme = LCDHandheldTheme()
    
    XCTAssertTrue(theme.isPremium)
    XCTAssertFalse(manager.isThemeAvailable(theme))
}
```

## Future Enhancements

### Community Themes

- Allow users to create/share custom themes
- JSON-based theme definitions
- Theme marketplace

### Seasonal Themes

- Halloween theme (October)
- Holiday theme (December)
- Unlock automatically during seasons

### Dynamic Themes

- Change colors based on time of day
- React to music (if music player added)
- Performance-based (colors shift with score)

## References

- Game Boy color palette: [Game Boy Camera Club](https://gameboycameraclub.com/blog/game-boy-hex-colors)
- CRT shader effects: [Shadertoy](https://www.shadertoy.com/)
- Accessibility guidelines: [Apple HIG - Color and Contrast](https://developer.apple.com/design/human-interface-guidelines/color)
