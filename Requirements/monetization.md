# Monetization – Daily Play Limit & Unlimited Plays

## Terminology

User-facing copy uses **Unlimited Plays** consistently (not “Premium”):

- **Primary offer**: One-time purchase of **Unlimited Plays** — no daily limit, play as much as you want.
- **Extras**: Benefits such as choosing visual themes (e.g. Pocket) are framed as **bonuses** that come with Unlimited Plays, not as a separate “premium tier”.

Internal code may still use names like `hasPremiumAccess` for the entitlement; the product and all user-visible text refer to **Unlimited Plays**.

## Overview

RetroRacing uses a **freemium** model with:

- **Free tier**: up to **6 games per calendar day** (resets at local midnight)
- **Unlimited Plays**: one‑time purchase (non‑consumable IAP) that removes the daily limit and includes theme choices as an extra

The goal is to encourage support without making the free experience feel hostile. Messaging focuses on **supporting the game** (buying coffee) rather than hard paywalling.

## Business Rules

### Free Tier

- A “game” is counted **per round**:
  - A round starts when a new `GameScene` is created (menu → game).
  - Restarts after game over **also count as new rounds**.
- Free users can play **6 rounds per calendar day** (`maxPlaysPerDay = 6`).
- The day boundary is based on the user’s **current Calendar and time zone** and resets at **00:00 local time**.
- When the limit is reached:
  - Starting a new game from the menu **shows the paywall**.
  - Restarting from the game over alert **shows the paywall** instead of restarting.

### Unlimited Plays (purchase)

- **Product**: `com.retroRacing.unlimitedPlays`
- **Type**: Non‑consumable, one‑time purchase.
- **Entitlement**:
  - Grants **unlimited plays forever** (no daily limit).
  - Unlocks **Pocket theme** and theme selection as an **extra** on iOS/tvOS/macOS/visionOS (watchOS keeps Pocket as the default theme for everyone).
- StoreKit 2’s **on‑device verification** is used; **no server** is required.
- Entitlement works across devices with the same Apple ID and survives app deletion/reinstallation.

## Architecture

### Play Limit Service

**File:** `RetroRacingShared/Services/Protocols/PlayLimitService.swift`  
**Implementation:** `RetroRacingShared/Services/Implementations/UserDefaultsPlayLimitService.swift`

Responsibilities:

- Track daily play count and reset at midnight.
- Decide whether a new game can start.
- Provide remaining plays and next reset date.
- Persist premium unlock (`hasUnlimitedAccess`).

Key API:

- `var hasUnlimitedAccess: Bool { get }`
- `func canStartNewGame(on date: Date) -> Bool`
- `func recordGamePlayed(on date: Date)`
- `func remainingPlays(on date: Date) -> Int`
- `func nextResetDate(after date: Date) -> Date`
- `func unlockUnlimitedAccess()`

Implementation details:

- Backed by `UserDefaults` with keys:
  - `"PlayLimit.lastPlayDate"`
  - `"PlayLimit.todayCount"`
  - `"PlayLimit.hasUnlimitedAccess"`
- Uses a **serial queue** for thread‑safety.
- Uses injected `Calendar` (defaults to `.current`) for day boundaries.

### StoreKit Service

**File:** `RetroRacingShared/Services/StoreKitService.swift`

Responsibilities:

- Load StoreKit products (currently one non‑consumable).
- Handle purchases and verify transactions.
- Refresh current entitlements.
- Expose `hasPremiumAccess` and `debugPremiumEnabled` for UI & testing.

Key API:

- `public enum ProductID: String { case unlimitedPlays = "com.retroRacing.unlimitedPlays" }`
- `public private(set) var products: [Product]`
- `public private(set) var purchasedProductIDs: Set<String>`
- `public var hasPremiumAccess: Bool`
- `public var debugPremiumEnabled: Bool`
- `public func loadProducts() async`
- `public func purchase(_ product: Product) async throws -> Transaction?`
- `public func restorePurchases() async throws`

`hasPremiumAccess` logic:

- Returns `true` when `debugPremiumEnabled` is `true` (for testing).
- Otherwise, returns `true` if there is **at least one current entitlement** in `Transaction.currentEntitlements`.

**Important**: 
- `debugPremiumEnabled` **defaults to `false`** to ensure App Store reviewers experience the free tier.
- The Debug section (with the toggle) is **hidden** in Release builds via `BuildConfiguration.shouldShowDebugFeatures`.
- `StoreKitService.hasPremiumAccess` is the **single source of truth** for premium status. All UI checks (MenuView, GameView, SettingsView) check this property **first** before falling back to `PlayLimitService` checks. This ensures premium users **always** have unlimited plays regardless of `PlayLimitService` state.

### Build Configuration Helper

**File:** `RetroRacingShared/Utilities/BuildConfiguration.swift`

- Detects **DEBUG**, **TestFlight**, and **Release**:
  - `isDebug`: compile‑time.
  - `isTestFlight`: via `AppTransaction.shared` environment (`.sandbox`).
  - `shouldShowDebugFeatures`: `isDebug || isTestFlight`.
- `initializeTestFlightCheck()` is called early from `RetroRacingApp` and `RetroRacingTvOSApp`.

Used to:

- Gate the **Debug** section in Settings.
- Allow `Simulate Premium Access` in DEBUG/TestFlight builds.

### App‑Level Injection

**Universal (iOS/iPadOS/macOS)**  
**File:** `RetroRacingUniversal/App/RetroRacingApp.swift`

- Creates shared instances:
  - `StoreKitService`
  - `UserDefaultsPlayLimitService`
  - `ThemeManager`
- Injects into environment and views:

```swift
BuildConfiguration.initializeTestFlightCheck()
playLimitService = UserDefaultsPlayLimitService(userDefaults: userDefaults)

NavigationStack {
    rootView
        .environment(storeKitService)
        .task {
            await storeKitService.loadProducts()
        }
}
```

**Important**: `loadProducts()` is called on app launch via `.task` to ensure entitlements are loaded **before** the user navigates to Settings or the Paywall. This ensures premium users see their status immediately.

`GameView` and `MenuView` receive `playLimitService` via their initialisers.

**tvOS**  
**File:** `RetroRacingTvOS/App/RetroRacingTvOSApp.swift`

- Same pattern:
  - `StoreKitService` injected via `.environment(storeKitService)`.
  - `UserDefaultsPlayLimitService` injected into `GameView` and `MenuView`.

**watchOS**

- Creates `UserDefaultsPlayLimitService` but does not currently expose paywall UI.
- Pocket theme remains default and free on watchOS.

### Theme Unlocks

**File:** `RetroRacingShared/Theme/ThemeManager.swift`

- Tracks free vs. premium themes and unlocked IDs.
- Premium themes can be unlocked explicitly via:
  - `unlockTheme(_ theme: GameTheme)`
  - `unlockPremiumThemes()`
- New helper:
  - `isThemeAccessible(id: String) -> Bool`

**Current behaviour:**

- `LCDTheme` is free and always available.
- `PocketTheme` is available on watchOS by default.
- On other platforms, `PocketTheme` can be treated as a **bonus** for premium users by:
  - Unlocking it when unlimited plays are purchased.
  - Using `ThemeManager`’s unlock APIs from the composition root when premium is detected (future enhancement).

> Note: The initial implementation wires premium access to **unlimited plays only**. Wiring premium to theme unlocks is kept flexible for future iterations.

## UI Integration

### Menu – Play Button

**File:** `RetroRacingShared/Views/MenuView.swift`

- Injected dependencies: 
  - `playLimitService: PlayLimitService?`
  - `@Environment(StoreKitService.self) private var storeKit`
- When user taps **Play**:

```swift
onPlay: {
    // Premium users always have unlimited plays
    if storeKit.hasPremiumAccess {
        if let onPlayRequest {
            onPlayRequest()
        } else {
            showGame = true
        }
    } else if let service = playLimitService,
              service.canStartNewGame(on: Date()) == false {
        showPaywall = true
    } else if let onPlayRequest {
        onPlayRequest()
    } else {
        showGame = true
    }
}
```

- **Premium users** (via `storeKit.hasPremiumAccess`) **always bypass** the play limit check.
- **Free users** are checked against the daily limit; if reached, the **paywall sheet** is presented.

### Game – Restart Button

**File:** `RetroRacingShared/Views/GameView.swift`

- Injected dependencies: 
  - `playLimitService: PlayLimitService?`
  - `@Environment(StoreKitService.self) private var storeKit`
- Game over alert:

```swift
Button(GameLocalizedStrings.string("restart")) {
    // Premium users always have unlimited plays
    if storeKit.hasPremiumAccess {
        model.restartGame()
    } else if let playLimitService, playLimitService.canStartNewGame(on: Date()) {
        model.restartGame()
    } else if playLimitService != nil {
        isPaywallPresented = true
    } else {
        model.restartGame()
    }
}
```

- Restart is blocked and the **paywall sheet** is shown when the limit is reached.

### Recording Games Played

**File:** `RetroRacingShared/Views/GameViewModel+Scene.swift`

- When a new `GameScene` is created (menu → game):

```swift
playLimitService?.recordGamePlayed(on: Date())
```

- When the game is restarted after game over:

```swift
// In restartGame()
playLimitService?.recordGamePlayed(on: Date())
```

- This ensures one count **per round** (every game start or restart).

### Paywall View

**File:** `RetroRacingShared/Views/PaywallView.swift`

Key elements:

- **Header** (`PaywallHeaderView`):
  - Icon: `gamecontroller.fill`
  - Title: `"paywall_title"` (“Unlock Unlimited Games”)
  - Caption `"paywall_caption_coffee"` (coffee/support copy; mentions unlocking Unlimited Plays).
- **Navigation title**: `"paywall_go_premium"` (displayed as “Unlock Unlimited Plays” / “Partidas ilimitadas” etc.).
- **Product card** (`ProductRow`):
  - Shows product name (`"product_unlimited_plays"`) and price.
  - Button triggers StoreKit 2 purchase.
- **Restore Purchases button**:
  - Shows loading state while restoring.
  - Disabled during purchase or restore operations.
  - Matches Settings → Purchases functionality.
- **Benefits text**:
  - `"paywall_unlimited_and_themes"` – unlimited plays first, theme choice as an extra.
  - Positioned below restore button, styled as secondary text.
- **Info cards** (`PaywallInfoCard`):
  - Giving Back – explains that a percentage goes to accessibility/inclusion.
  - Want to Stay Free? – explains daily reset and “See you tomorrow!” message.
- **Footer**: `"paywall_footer_one_time"` – one‑time purchase, no subscription, unlocks unlimited plays forever.

Purchase handling:

```swift
let transaction = try await storeKit.purchase(product)
if transaction != nil {
    playLimitService?.unlockUnlimitedAccess()
    onPurchaseCompleted?()
    showingSuccess = true
}
```

Restore handling:

```swift
try await storeKit.restorePurchases()
if storeKit.hasPremiumAccess {
    playLimitService?.unlockUnlimitedAccess()
    onPurchaseCompleted?()
    showingRestoreAlert = true  // Success message
} else {
    showingRestoreAlert = true  // No purchases found
}
```

### Settings – Play Limit & Purchases

**File:** `RetroRacingShared/Views/SettingsView.swift`

Sections added:

1. **Play Limit** (only visible for **free users**)
   - Title: `"play_limit_title"`
   - Free users:
     - `"play_limit_remaining %lld"` – “Remaining: X of 6”
     - Subtitle:
       - `"play_limit_resets_tomorrow"` or
       - `"play_limit_resets_in_hours %lld"`.
   - **Note**: This entire section is **hidden** for premium users (via `if let playLimitService, !storeKit.hasPremiumAccess`) since they have unlimited plays.

2. **Purchases**
   - Unlimited Plays row (when owned):
     - `"settings_premium_active"` (displayed as “Unlimited Plays”) + `"product_unlimited_plays"`.
   - Free users:
     - “Learn About Unlimited Plays” → opens Paywall.
     - “Redeem Code” → opens System offer code redemption UI.
     - “Restore Purchases” → invokes `storeKit.restorePurchases()`.
   - Footer:
     - `"settings_restore_footer"`.

3. **Debug (DEBUG/TestFlight only)**
   - Toggle: `"debug_simulate_premium"` (displayed as “Simulate Unlimited Plays”) bound to `storeKit.debugPremiumEnabled`.
   - Footer: `"debug_simulate_premium_footer"`.
   - **Note**: This entire section is **hidden** in Release builds (via `BuildConfiguration.shouldShowDebugFeatures`).

An **About** section remains at the bottom with a link to `AboutView`.

## Localization

**File:** `RetroRacingShared/Localizable.xcstrings`

- New keys for:
  - Play limit titles, remaining text, reset messages, thank‑you message.
  - Paywall header and coffee caption.
  - Giving Back / Stay Free copy.
  - Buttons (Redeem Code, Restore Purchases).
  - Purchase success/error/restore messages.
  - Settings purchase section and Debug section.
- Localised into:
  - **English** (`en`)
  - **Spanish** (`es`) – present perfect where appropriate.
  - **Catalan (Valencià meridional)** (`ca`).

## Testing

### Unit Tests

**File:** `RetroRacingSharedTests/PlayLimitServiceTests.swift`

Scenarios covered:

- Initial state allows **6 games** in a day, blocks the 7th.
- Counter **resets at midnight** (calendar day change).
- `unlockUnlimitedAccess()`:
  - `hasUnlimitedAccess == true`
  - `canStartNewGame` always returns `true`.
  - `remainingPlays == Int.max`.
- `nextResetDate(after:)` returns next midnight.

### Manual QA Checklist

- Free user:
  - Can play up to 6 games in a single day.
  - 7th attempt from menu → paywall appears.
  - Restart after limit reached → paywall appears.
  - Next day: counter resets and 6 plays are available again.
- Premium user:
  - No play limit (unbounded sessions).
  - Settings shows “♾️ Unlimited” + thank‑you message.
  - Paywall is still reachable from Settings but purchase is essentially a no‑op.
- Debug/TestFlight:
  - Debug section visible in Settings.
  - “Simulate Premium Access” instantly toggles premium UI and removes limits.

## App Store Connect Setup (Summary)

See plan for full details; key points:

- Create **Non‑Consumable IAP**:
  - ID: `com.retroRacing.unlimitedPlays`
  - Name: “Unlimited Plays”
  - Description explains 6 games/day limit and unlimited unlock.
- Localise display name/description into EN/ES/CA.
- Provide at least one screenshot showing:
  - The paywall.
  - The Settings Play Limit section.

## Future Enhancements

- Tie premium entitlement to automatic unlocking of **all premium themes** via `ThemeManager.unlockPremiumThemes()`.
- Add remote configuration to tweak:
  - `maxPlaysPerDay`
  - messaging
  - pricing experiments (A/B).
- Extend paywall to show more detailed **value proposition** (themes, future content, etc.).

