# Monetization – Daily Play Limit & Unlimited Plays

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Freemium daily play limits, Unlimited Plays IAP, paywall triggers, and user-facing "Unlimited Plays" terminology.
- **Must not break:** Free tier 9 games first day then 3/day; each round/restart counts; premium bypasses limits; user copy never says "Premium".
- **Key files:** `PlayLimitService`, `StoreKitService`, paywall and game-over modal flows.

## Terminology

User-facing copy uses **Unlimited Plays** consistently (not “Premium”):

- **Primary offer**: One-time purchase of **Unlimited Plays** — no daily limit, play as much as you want.
- **Extras**: Benefits such as choosing visual themes (e.g. Pocket) are framed as **bonuses** that come with Unlimited Plays, not as a separate “premium tier”.

Internal code may still use names like `hasPremiumAccess` for the entitlement; the product and all user-visible text refer to **Unlimited Plays**.

## Overview

RetroRacing uses a **freemium** model with:

- **Free tier**: up to **9 games on the first play day** (welcome bonus), then **3 games per calendar day** from day 2 onward (resets at local midnight). Reinstalling the app resets the bonus.
- **Unlimited Plays**: one‑time purchase (non‑consumable IAP) that removes the daily limit and includes theme choices as an extra

The goal is to encourage support without making the free experience feel hostile. Messaging focuses on **supporting the game** (buying coffee) rather than hard paywalling.

## Business Rules

### Free Tier

- A “game” is counted **per round**:
  - A round starts when a new `GameScene` is created (menu → game).
  - Restarts after game over **also count as new rounds**.
- Free users can play **9 rounds on their first play day** (`firstDayMaxPlays = 9`) and **3 rounds per calendar day** from day 2 onward (`maxPlaysPerDay = 3`). "First play day" is the calendar day on which `recordGamePlayed` is first called (stored as `PlayLimit.firstPlayDate`). Reinstalling the app clears UserDefaults, resetting the bonus.
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

## SharePlay Exception

**Framing:** "Friend races are free." SharePlay competitive matches (see
[`Requirements/shareplay_multiplayer.md`](shareplay_multiplayer.md)) are **always free** for
every player, regardless of `StoreKitService.hasPremiumAccess` or `PlayLimitService` state, and
they **never consume a daily play**.

- **Entry point**: The **Play with Friends** button in `MenuView`/`MenuContentView` calls
  `onPlayWithFriendsRequest` directly — it never routes through the `PlayLimitService`/paywall
  check that gates the regular **Play** button.
- **Recording skip**: `GameViewModel.isSharePlayActive` (true whenever
  `SharePlayMatchState.isActive` is true, i.e. not `.idle`) gates every
  `playLimitService?.recordGamePlayed(on:)` call site, mirroring the existing
  `specialEventService?.isEventActive(on:)` skip:
  - `GameViewModel+Gameplay.swift` (`restartGame()`).
  - `GameViewModel+Scene.swift` (scene creation on menu → game transition).
- This applies even when the player has **zero remaining daily plays** — a SharePlay match can
  always start and does not deduct from, or get blocked by, the free-tier counter.
- **Difficulty lock**: While a SharePlay match is active, `MenuView` passes
  `isGameSessionInProgress: isSharePlayActive` into its `SettingsView` sheet, disabling
  difficulty editing (the round's difficulty is host-authoritative and shared with the guest for
  the match's duration; see `SharePlayGuestSpeedRestore`).
- **Copy**:
  - `menu_play_with_friends_free_footer` — visible footer below the Play with Friends button.
  - `menu_play_with_friends_free_hint` — explicit accessibility hint on the Play with Friends button.
  - `paywall_shareplay_free_notice` — Play with Friends card body in `PaywallView`'s
    limit-triggered "Want to Stay Free?" section, reminding players who hit the daily cap that
    SharePlay matches are still available for free.
  - SharePlay-related paywall/body copy should avoid em dashes and must be translated in the
    shared string catalog for English, Spanish, and Catalan locales.

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
- `func maxPlays(on date: Date) -> Int` — returns `Int.max` for unlimited users; `firstDayMaxPlays` on the first play day; `maxPlaysPerDay` thereafter.
- `func isFirstPlayDay(on date: Date) -> Bool` — `true` when `date` is the calendar day on which the first game was ever recorded.
- `func nextResetDate(after date: Date) -> Date`
- `func unlockUnlimitedAccess()`

Implementation details:

- Backed by `UserDefaults` with keys:
  - `"PlayLimit.lastPlayDate"`
  - `"PlayLimit.todayCount"`
  - `"PlayLimit.hasUnlimitedAccess"`
  - `"PlayLimit.firstPlayDate"` (set on the first `recordGamePlayed` call; cleared on reinstall)
  - `"PlayLimit.debugForceFreemium"` (debug override written by `StoreKitService`)
- Thread-safety is provided by the project's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` build setting (no `DispatchQueue` required).
- Uses injected `Calendar` (defaults to `.current`) for day boundaries.
- `hasUnlimitedAccess` and all limit checks (`canStartNewGame`, `recordGamePlayed`, `remainingPlays`) ignore stored unlimited access when `"PlayLimit.debugForceFreemium" == true`.

### StoreKit Service

**File:** `RetroRacingShared/Services/StoreKitService.swift`

Responsibilities:

- Load StoreKit products (currently one non‑consumable).
- Handle purchases and verify transactions.
- Refresh current entitlements.
- Expose `hasPremiumAccess`, gating helpers, and `debugPremiumSimulationMode` for UI & testing.
- Persist the last verified premium state locally so returning purchasers are not briefly treated as free while StoreKit resolves on cold launch.

Key API:

- `public enum ProductID: String { case unlimitedPlays = "com.accessibilityUpTo11.RetroRacing.unlimitedPlays" }`
- `public private(set) var products: [Product]`
- `public private(set) var purchasedProductIDs: Set<String>`
- `public var hasPremiumAccess: Bool` — live (or debug-simulated) entitlement state
- `public var hasPremiumAccessForGating: Bool` — uses cached premium until the first live entitlement check resolves; then live only
- `public var shouldShowFreeTierAffordances: Bool` — `true` only after entitlements resolve **and** the user is not premium; withholds free CTAs during the resolve window
- `public private(set) var hasResolvedInitialEntitlements: Bool`
- `public var onEntitlementsUpdated: ((Bool) -> Void)?` — fired with the real StoreKit result after every refresh
- `public enum DebugPremiumSimulationMode { case productionDefault, unlimitedPlays, freemium }`
- `public var debugPremiumSimulationMode: DebugPremiumSimulationMode`
- `public func loadProducts() async`
- `public func purchase(_ product: Product) async throws -> Transaction?`
- `public func restorePurchases() async throws`
- `public func hasPurchased(_ productID: String) -> Bool`

Local cache keys (`UserDefaults`):

- `"StoreKit.cachedPremiumAccess"`
- `"StoreKit.lastEntitlementCheck"` (stamp only; no TTL)

`hasPremiumAccess` logic:

- `.productionDefault`: returns `true` if there is **at least one current entitlement** in `Transaction.currentEntitlements`.
- `.unlimitedPlays`: always returns `true` (forces paid behavior for testing).
- `.freemium`: always returns `false` (forces free behavior for testing).

**Important**: 
- `debugPremiumSimulationMode` **defaults to `.productionDefault`**.
- Simulation overrides are active only when `StoreKitService` is created with `isDebugSimulationEnabled == true` (default: `BuildConfiguration.isDebug`).
- The Debug section (with the picker) is **hidden** when `BuildConfiguration.shouldShowDebugFeatures == false`.
- **Play bypass and premium UI chrome** use `hasPremiumAccessForGating`. **Free-tier affordances** (Support CTA, play-limit section, purchase CTAs) use `shouldShowFreeTierAffordances`. **Purchase/restore feedback** keeps live `hasPremiumAccess`.
- `StoreKitService` starts an independent entitlement refresh in `init` so a product-catalog failure cannot delay premium resolution.
- Composition roots wire `onEntitlementsUpdated` to `PlayLimitService.unlockUnlimitedAccess()` / `clearUnlimitedAccess()` so the play-limit store stays aligned with live entitlements.
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
let playLimit = UserDefaultsPlayLimitService(userDefaults: userDefaults)
playLimitService = playLimit
storeKitService.onEntitlementsUpdated = { isPremium in
    if isPremium { playLimit.unlockUnlimitedAccess() }
    else { playLimit.clearUnlimitedAccess() }
}

NavigationStack {
    rootView
        .environment(storeKitService)
        .task {
            await storeKitService.loadProducts()
        }
}
```

**Important**: `loadProducts()` still loads the product catalog on launch. Entitlement resolution also runs independently in `StoreKitService.init`, and the local premium cache is seeded from `UserDefaults` before the first UI frame so returning purchasers do not flash free-tier chrome.

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
    if storeKit.hasPremiumAccessForGating {
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

- **Premium users** (via `storeKit.hasPremiumAccessForGating`) **always bypass** the play limit check.
- **Free users** are checked against the daily limit; if reached, the **paywall sheet** is presented.

### Menu – Support CTA

**File:** `RetroRacingShared/Views/MenuView.swift` + `RetroRacingShared/Views/MenuContentView.swift`

- Universal menu includes an engagement block after **Play** and **Leaderboard**:
  - Prompt: `"menu_engagement_prompt"` (for example, “Enjoying RetroRapid!?”)
  - Rate action: `"menu_rate_game"` (opens App Store write-review URL)
  - Support action: `"menu_support_game"` (opens paywall sheet)
- Support CTA visibility:
  - **Shown** when `showRateButton == true` and `storeKit.shouldShowFreeTierAffordances == true`.
  - **Hidden** while entitlements are still resolving, and when Unlimited Plays is active (live or cached).
- Rate CTA visibility:
  - **Hidden** when `storeKit.hasPremiumAccessForGating == true` (including cached premium on launch).
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
    if storeKit.hasPremiumAccessForGating {
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
  - Cards expand to the full paywall content width (`.frame(maxWidth: .infinity)`).
  - Nested cards under the limit-triggered **Want to Stay Free?** heading omit per-card
    accessibility header traits; the section heading remains the sole header for that group.
  - **Giving Back** (always shown): AMMEC donation explanation with Learn More link (in-app SafariView on iOS, `openURL` elsewhere).
  - **Want to Stay Free?** (limit-triggered only): section heading followed by three sibling cards:
    - **No worries!** (`paywall_stay_free_reset_title` / `paywall_stay_free_reset_body`): "Your daily limit resets at midnight."
    - **Apple Watch** (`paywall_stay_free_watch_title` / `paywall_stay_free_watch_body`): "Keep playing as much as you want on your Apple Watch."
    - **Play with Friends** (`menu_play_with_friends` / `paywall_shareplay_free_notice`): "Friend races are free with SharePlay!"
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

Settings order in the shared view is: **Play Limit**, **Purchases**, **Theme**, **Font**, **Speed**, **Sound**, **Vibration**, **Controls**, **Accessibility**, **About**, **Debug**.

1. **Play Limit** (only visible for **free users**)
   - Title: `"play_limit_title"`
   - Free users:
     - `"play_limit_remaining %lld"` – “Remaining: X of 5”
     - Subtitle:
       - `"play_limit_resets_tomorrow"` or
       - `"play_limit_resets_in_hours %lld"`.
     - Row accessibility is combined (`.accessibilityElement(children: .combine)`).
   - Footer copy:
     - `"play_limit_section_footer %lld"` — daily allowance without Unlimited Plays; `%lld` is the
       standard daily max derived from `PlayLimitService.maxPlays(on:)` (using the next calendar day
       while the welcome bonus is active so the daily value stays accurate).
     - `"play_limit_section_footer_first_day %lld %lld"` — same daily max plus the first-day welcome
       bonus max from `PlayLimitService.maxPlays(on:)` on the current day.
   - **Note**: This entire section is **hidden** for premium users (via `if let playLimitService, storeKit.shouldShowFreeTierAffordances`) since they have unlimited plays.

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

3. **Theme**
   - When Unlimited Plays is not active, the Theme section footer shows:
     - `"settings_theme_unlock_footnote"` (soft prompt to unlock Unlimited Plays from Purchases).
   - Non-premium Theme row remains a single combined accessibility element (`Theme`, current value).

4. **Controls**
   - The top-level Settings list shows one `"settings_controls_how_to_play"` row.
   - The row opens a Settings help sheet with the current platform controls copy first.
   - On shared controller-supported settings surfaces, the sheet also contains controller remapping pickers and the existing `"settings_controller_footnote"`.

5. **Debug (DEBUG only)**
   - Picker: `"debug_simulate_premium"` (displayed as “Simulate Unlimited Plays”) bound to `storeKit.debugPremiumSimulationMode`.
   - Options:
     - `"debug_simulation_mode_default"` (Default / production behavior).
     - `"debug_simulation_mode_unlimited"` (forces Unlimited Plays).
     - `"debug_simulation_mode_freemium"` (forces free-tier behavior).
   - Footer: `"debug_simulate_premium_footer"`.
   - Debug also exposes force-achievement selection and SpriteKit frame stats in DEBUG builds; the GAAD Achievement QA panel is not shown in Settings.
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

- Initial state (first play day) allows **9 games**, blocks the 10th.
- Day 2 onward allows **3 games**, blocks the 4th.
- First play day is detected via `PlayLimit.firstPlayDate` (set on first `recordGamePlayed` call).
- Counter **resets at midnight** (calendar day change).
- `unlockUnlimitedAccess()`:
  - `hasUnlimitedAccess == true`
  - `canStartNewGame` always returns `true`.
  - `remainingPlays == Int.max`.
- `nextResetDate(after:)` returns next midnight.

### Manual QA Checklist

- Free user:
  - First play day: can play up to 9 games. 10th attempt from menu → paywall appears.
  - Day 2+: can play up to 3 games. 4th attempt from menu → paywall appears.
  - Restart after limit reached → paywall appears.
  - Next day: counter resets and 3 plays are available.
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
  - Description explains the daily limit (9 on first day, 3 from day 2) and unlimited unlock.
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
