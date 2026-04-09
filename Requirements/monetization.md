# Monetization – Daily Play Limit & Unlimited Plays

## Terminology

User-facing copy uses **Unlimited Plays** consistently (not “Premium”):

- **Primary offer**: One-time purchase of **Unlimited Plays** — no daily limit, play as much as you want.
- **Extras**: Benefits such as choosing visual themes (e.g. Pocket) are framed as **bonuses** that come with Unlimited Plays, not as a separate “premium tier”.

Internal code may still use names like `hasPremiumAccess` for the entitlement; the product and all user-visible text refer to **Unlimited Plays**.

## Overview

RetroRacing uses a **freemium** model with:

- **Free tier**: up to **5 games per calendar day** (resets at local midnight)
- **Unlimited Plays**: one‑time purchase (non‑consumable IAP) that removes the daily limit and includes theme choices as an extra

The goal is to encourage support without making the free experience feel hostile. Messaging focuses on **supporting the game** (buying coffee) rather than hard paywalling.

## Business Rules

### Free Tier

- A “game” is counted **per round**:
  - A round starts when a new `GameScene` is created (menu → game).
  - Restarts after game over **also count as new rounds**.
- Free users can play **5 rounds per calendar day** (`maxPlaysPerDay = 5`).
- The day boundary is based on the user’s **current Calendar and time zone** and resets at **00:00 local time**.
- When the limit is reached:
  - Starting a new game from the menu **shows the paywall**.
  - Restarting from the game-over modal **shows the paywall** instead of restarting.

### Unlimited Plays (purchase)

- **Product**: `com.accessibilityUpTo11.RetroRacing.unlimitedPlays`
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
  - `"PlayLimit.debugForceFreemium"` (debug override written by `StoreKitService`)
- Uses a **serial queue** for thread‑safety.
- Uses injected `Calendar` (defaults to `.current`) for day boundaries.
- `hasUnlimitedAccess` and all limit checks (`canStartNewGame`, `recordGamePlayed`, `remainingPlays`) ignore stored unlimited access when `"PlayLimit.debugForceFreemium" == true`.

### StoreKit Service

**File:** `RetroRacingShared/Services/StoreKitService.swift`

Responsibilities:

- Load StoreKit products (currently one non‑consumable).
- Handle purchases and verify transactions.
- Refresh current entitlements.
- Expose `hasPremiumAccess` and `debugPremiumSimulationMode` for UI & testing.

Key API:

- `public enum ProductID: String { case unlimitedPlays = "com.accessibilityUpTo11.RetroRacing.unlimitedPlays" }`
- `public private(set) var products: [Product]`
- `public private(set) var purchasedProductIDs: Set<String>`
- `public var hasPremiumAccess: Bool`
- `public enum DebugPremiumSimulationMode { case productionDefault, unlimitedPlays, freemium }`
- `public var debugPremiumSimulationMode: DebugPremiumSimulationMode`
- `public func loadProducts() async`
- `public func purchase(_ product: Product) async throws -> Transaction?`
- `public func restorePurchases() async throws`
- `public func hasPurchased(_ productID: String) -> Bool`

`hasPremiumAccess` logic:

- `.productionDefault`: returns `true` if there is **at least one current entitlement** in `Transaction.currentEntitlements`.
- `.unlimitedPlays`: always returns `true` (forces paid behavior for testing).
- `.freemium`: always returns `false` (forces free behavior for testing).

**Important**: 
- `debugPremiumSimulationMode` **defaults to `.productionDefault`**.
- Simulation overrides are active only when `StoreKitService` is created with `isDebugSimulationEnabled == true` (default: `BuildConfiguration.isDebug`).
- The Debug section (with the picker) is **hidden** when `BuildConfiguration.shouldShowDebugFeatures == false`.
- `StoreKitService.hasPremiumAccess` is the **single source of truth** for premium status. All UI checks (MenuView, GameView, SettingsView) check this property **first** before falling back to `PlayLimitService` checks. This ensures premium users **always** have unlimited plays regardless of `PlayLimitService` state.
- When `debugPremiumSimulationMode == .freemium`, `StoreKitService` writes the debug override key (`"PlayLimit.debugForceFreemium"`) so `PlayLimitService` behaves as unpaid even if the device has previously unlocked unlimited plays.
- `hasPurchased(_:)` **also respects `debugPremiumSimulationMode`**: it returns `false` in `.freemium` mode and `true` for the unlimited plays product in `.unlimitedPlays` mode. This ensures UI elements (e.g. `ProductRow` in the paywall) that use `hasPurchased` stay consistent with `hasPremiumAccess` under all debug states.

### Build Configuration Helper

**File:** `RetroRacingShared/Utilities/BuildConfiguration.swift`

- Detects **DEBUG** and runtime environment details:
  - `isDebug`: compile‑time.
  - `isTestFlight`: via `AppTransaction.shared` environment (`.sandbox`).
  - `shouldShowDebugFeatures`: `isDebug`.
- `initializeTestFlightCheck()` is called early from `RetroRacingApp` and `RetroRacingTvOSApp`.

Used to:

- Gate the **Debug** section in Settings.
- Allow debug simulation mode selection in DEBUG builds.

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
storeKitService = StoreKitService(userDefaults: userDefaults)
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

### Menu – Support CTA

**File:** `RetroRacingShared/Views/MenuView.swift` + `RetroRacingShared/Views/MenuContentView.swift`

- Universal menu includes an engagement block after **Play** and **Leaderboard**:
  - Prompt: `"menu_engagement_prompt"` (for example, “Enjoying RetroRapid!?”)
  - Rate action: `"menu_rate_game"` (opens App Store write-review URL)
  - Support action: `"menu_support_game"` (opens paywall sheet)
- Support CTA visibility:
  - **Hidden by default** until entitlement status is refreshed for the current menu session.
  - **Shown** when `showRateButton == true`, entitlement has been resolved, and `storeKit.hasPremiumAccess == false`.
  - **Hidden** when Unlimited Plays is already active.
  - Layout stability: support CTA keeps a reserved button slot in the menu stack so text/buttons do not jump when the entitlement result arrives.
- tvOS keeps `showRateButton = false`, so this engagement block is not shown there.

### Game – Restart Button

**File:** `RetroRacingShared/Views/GameView.swift`

- Injected dependencies: 
  - `playLimitService: PlayLimitService?`
  - `@Environment(StoreKitService.self) private var storeKit`
- Game-over modal (`GameOverView` in a `.sheet`):

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

The paywall has two distinct modes driven by the `isLimitReached: Bool` parameter:

**Voluntary mode** (`isLimitReached: false`): opened via "Back development" in the menu or from Settings. Leads with a personal profile picture and introduction to create human connection.

**Limit-triggered mode** (`isLimitReached: true`): opened automatically when the daily play limit is reached. More focused — skips the personal intro in favour of a playful on-brand limit notice.

`MenuView` uses a `PaywallTrigger` enum with `.sheet(item:)` to drive presentation cleanly:

```swift
enum PaywallTrigger: Identifiable {
    case limitReached
    case voluntary
    var id: Self { self }
}
```

`GameView` always passes `isLimitReached: true` directly.

Key elements:

- **Header** (`PaywallHeaderView`):
  - **Voluntary**: profile picture (`profilePicRetroRapid`, 80pt base with `@ScaledMetric(relativeTo: .largeTitle)`, `.clipShape(Circle())`), localized accessibility label (`"paywall_avatar_accessibility_label"`). Caption: `"paywall_caption_coffee"` ("Hi! I'm Dani. Consider unlocking...coffee...new features I hope you'll love.")
  - **Limit-triggered**: `gamecontroller.fill` SF Symbol (decorative, hidden from VoiceOver). No caption.
  - Title (`"paywall_title"`): "Get Unlimited Plays" — shown in both modes.
- **Navigation title** (`"paywall_go_premium"`): "Go Unlimited".
- **Limit notice** (limit-triggered only): `"paywall_limit_notice"` — "Pit stop! You've used up all your plays for today. Want to keep going? One coffee for me, unlimited plays for you!" Shown between header and product row.
- **Product card** (`ProductRow`):
  - Shows product name (`"product_unlimited_plays"`) and price.
  - When already owned, subtitle changes to `"purchase_success_message"`.
  - Purchased-state checkmark icon is decorative (hidden from accessibility).
  - Button triggers StoreKit 2 purchase.
- **Restore Purchases button**: shows loading state; disabled during purchase or restore.
- **Redeem Code button** (where platform supports offer-code redemption):
  - iOS: uses `.offerCodeRedemption(...)`.
  - macOS: uses `AppStore.presentOfferCodeRedeemSheet(from:)`.
  - Hidden on platforms without the offer-code UI.
- **Benefits text** (`"paywall_unlimited_and_themes"`): "Unlimited plays forever. Choose from available visual themes. Back development." Positioned below restore button.
- **Info cards** (`PaywallInfoCard`):
  - **Giving Back** (always shown): AMMEC donation explanation with Learn More link (in-app SafariView on iOS, `openURL` elsewhere).
  - **Want to Stay Free?** (limit-triggered only): daily reset explanation — "No problem! Your daily limit resets at midnight. Just wait a bit to enjoy the game again. See you tomorrow!"
- **Footer** (`"paywall_footer_one_time"`): one-time purchase, no subscription, unlocks unlimited plays forever.

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

0. **Theme**
   - When Unlimited Plays is not active, the Theme section footer shows:
     - `"settings_theme_unlock_footnote"` (soft prompt to unlock Unlimited Plays from Purchases).
   - Non-premium Theme row remains a single combined accessibility element (`Theme`, current value).

1. **Play Limit** (only visible for **free users**)
   - Title: `"play_limit_title"`
   - Free users:
     - `"play_limit_remaining %lld"` – “Remaining: X of 5”
     - Subtitle:
       - `"play_limit_resets_tomorrow"` or
       - `"play_limit_resets_in_hours %lld"`.
     - Row accessibility is combined (`.accessibilityElement(children: .combine)`).
   - **Note**: This entire section is **hidden** for premium users (via `if let playLimitService, !storeKit.hasPremiumAccess`) since they have unlimited plays.

2. **Purchases**
   - Unlimited Plays row (when owned):
     - `"settings_premium_active"` (displayed as “Unlimited Plays”) + `"settings_premium_active_subtitle"` (e.g. “Endless play and choose your favorite theme.”).
     - Row accessibility is combined (`.accessibilityElement(children: .combine)`).
     - Checkmark icon is decorative and hidden from accessibility (`.accessibilityHidden(true)`).
   - Free users:
    - “Get Unlimited Plays” → opens Paywall.
     - “Redeem Code”:
       - iOS: uses SwiftUI `.offerCodeRedemption(...)`.
       - macOS: uses StoreKit `AppStore.presentOfferCodeRedeemSheet(from:)` with an embedded host `NSViewController`.
     - “Restore Purchases” → invokes `storeKit.restorePurchases()`.
   - Footer:
     - `"settings_restore_footer"`.

3. **Debug (DEBUG only)**
   - Picker: `"debug_simulate_premium"` (displayed as “Simulate Unlimited Plays”) bound to `storeKit.debugPremiumSimulationMode`.
   - Options:
     - `"debug_simulation_mode_default"` (Default / production behavior).
     - `"debug_simulation_mode_unlimited"` (forces Unlimited Plays).
     - `"debug_simulation_mode_freemium"` (forces free-tier behavior).
   - Footer: `"debug_simulate_premium_footer"`.
   - **Note**: This entire section is **hidden** in Release builds (via `BuildConfiguration.shouldShowDebugFeatures`).

An **About** section appears above Debug, and Debug remains the final section in the list.

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

- Initial state allows **5 games** in a day, blocks the 6th.
- Counter **resets at midnight** (calendar day change).
- `unlockUnlimitedAccess()`:
  - `hasUnlimitedAccess == true`
  - `canStartNewGame` always returns `true`.
  - `remainingPlays == Int.max`.
- `nextResetDate(after:)` returns next midnight.

### Manual QA Checklist

- Free user:
  - Can play up to 5 games in a single day.
  - 6th attempt from menu → paywall appears.
  - Restart after limit reached → paywall appears.
  - Next day: counter resets and 5 plays are available again.
- Premium user:
  - No play limit (unbounded sessions).
  - Settings shows “♾️ Unlimited” + thank‑you message.
  - Paywall is still reachable from Settings but purchase is essentially a no‑op.
- Debug:
  - Debug section visible in Settings.
  - “Default” uses real entitlement state.
  - “Unlimited Plays” forces premium UI and bypasses limits.
  - “Freemium” forces free-tier behavior.

## App Store Connect Setup (Summary)

See plan for full details; key points:

- Create **Non‑Consumable IAP**:
  - ID: `com.accessibilityUpTo11.RetroRacing.unlimitedPlays`
  - Name: “Unlimited Plays”
  - Description explains 5 games/day limit and unlimited unlock.
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
