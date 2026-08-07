# Monetization and Unlimited Plays

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Free daily play limits, Unlimited Plays IAP, paywall triggers, purchase/restore gating, and free SharePlay races.
- **Must not break:** Free tier is 9 rounds on first play day then 3/day; each solo round/restart counts; Unlimited Plays bypasses limits; SharePlay matches are always free; user copy says “Unlimited Plays”, not “Premium”.
- **Key files:** `PlayLimitService`, `UserDefaultsPlayLimitService`, `StoreKitService`, `PaywallView`, `MenuView`, `GameView`, `SettingsView`.

## Product Terms

- User-facing entitlement: **Unlimited Plays**.
- Product ID: `com.accessibilityUpTo11.RetroRacing.unlimitedPlays`.
- Product type: non-consumable, one-time purchase.
- Internal code may still use `premium` names for entitlement state, but user-visible copy must prefer Unlimited Plays.
- Unlimited Plays removes solo daily limits forever and may unlock theme-selection extras where the platform supports them.

## Free-Tier Rules

- A counted “game” is one solo round:
  - menu → game counts once when the scene is created
  - restart after game over counts as a new round
- First play day allows 9 rounds. The first play day is the local calendar day when `recordGamePlayed(on:)` first stores `PlayLimit.firstPlayDate`.
- Later local calendar days allow 3 rounds per day.
- The counter resets at local midnight using the injected/current `Calendar`.
- Reinstalling clears UserDefaults and resets the welcome bonus.
- When a free user is out of plays:
  - tapping Play from the menu shows the paywall
  - tapping Restart from game over shows the paywall

## Entitlement and Gating

- StoreKit 2 current entitlements are authoritative after the initial entitlement refresh resolves.
- `StoreKitService.hasPremiumAccessForGating` may use the cached premium flag before first resolve so returning purchasers do not flash free-tier UI on cold launch.
- `StoreKitService.shouldShowFreeTierAffordances` is true only after entitlements resolve and the user is not entitled.
- Composition roots sync entitlement updates into `PlayLimitService.unlockUnlimitedAccess()` or `clearUnlimitedAccess()`.
- `PlayLimitService` methods must bypass counting and return unlimited availability when unlimited access is active, except when DEBUG freemium simulation forces free-tier behavior.
- Purchase and restore success must unlock the play-limit service and dismiss or refresh paywall UI without requiring app restart.

## SharePlay Exception

Friend races are free. SharePlay competitive matches in [`shareplay_multiplayer.md`](shareplay_multiplayer.md) must never use daily plays.

- The **Play with Friends** menu action does not call the regular play-limit/paywall gate.
- Each platform's session owner gates solo play recording while SharePlay is active (`GameViewModel.isSharePlayActive` on shared `GameView` platforms and `VisionGameSessionCoordinator.isSharePlayActive` on visionOS).
- A SharePlay match can start even when the player has zero solo plays remaining.
- SharePlay-related free copy appears only where free-tier affordances are appropriate; Unlimited Plays users should not see free-tier upsell footers.
- Difficulty editing is locked while a SharePlay match is active because the host’s speed is authoritative for the current match.

## UI Contract

- Menu:
  - Play uses `hasPremiumAccessForGating` before checking `PlayLimitService`.
  - Rate/support engagement is hidden for Unlimited Plays users and while entitlement state is unresolved.
- Game over:
  - Restart uses `hasPremiumAccessForGating` before checking remaining plays.
  - Solo game-over is suppressed while SharePlay is active.
- Paywall:
  - Supports voluntary and limit-triggered modes.
  - Limit-triggered mode shows the limit notice and “Want to Stay Free?” cards, including the free SharePlay reminder.
  - Restore and redeem actions stay platform-appropriate.
- Settings:
  - Play Limit section is visible only for resolved free users.
  - Purchases section exposes Get Unlimited Plays, Restore Purchases, and supported redeem-code UI.
  - Purchases appears near the top for users without Unlimited Plays; after purchase it moves below About, while DEBUG-only controls remain last in debug builds.
  - Debug simulation controls are DEBUG-only; see [debug_simulation.md](debug_simulation.md).

## App Store and Operations

- Pricing, IAP localization, screenshots, and review-note operations live under [AppStore/README.md](../AppStore/README.md) and [Plans/aso/04-pricing-strategy.md](../Plans/aso/04-pricing-strategy.md).
- Product ID and localized IAP metadata must stay aligned with `StoreKitService.ProductID.unlimitedPlays`.
- App Review should be able to reach the free limit and purchase flow from a fresh install without debug state.

## Testing

- Unit tests cover first-day and later-day limits, local-midnight reset, unlimited-access bypass, cached entitlement gating, purchase/restore callbacks, debug freemium override, and SharePlay record-skip behavior.
- Manual release checks cover fresh install free flow, sandbox purchase, restore after reinstall, refund/revocation behavior, and Release/TestFlight builds hiding debug simulation.
