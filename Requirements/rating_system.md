# Rating System

## Overview

RetroRacing uses a hybrid rating strategy to improve reliability and timing:

- **Manual intent (Rate buttons):** Open the App Store write-review page directly.
- **Automatic timing (in-app prompt):** Use StoreKit native prompt after repeated positive gameplay signals.

This avoids over-relying on explicit user-triggered StoreKit prompt calls, which may stop showing.

## Architecture

### Manual Rating Entry Points

- Shared URL source: `RetroRacing/RetroRacingShared/Utilities/AppStoreReviewURL.swift`
  - `AppStoreReviewURL.writeReview`
  - `https://apps.apple.com/app/id6758641625?action=write-review`
- Universal menu engagement CTA (`MenuView` key: `menu_rate_game`, label: "Rate it") opens the URL via `openURL`.
  - Hidden for Unlimited Plays purchasers once entitlement state resolves — asking someone who
    already paid to also rate the app on the home screen feels intrusive (see "Unlimited Plays
    Menu Exclusion" below).
- About screen button (`AboutView`) opens the same URL via `openURL`.
  - **Always shown**, regardless of premium status. Unlimited Plays purchasers who want to rate
    voluntarily can still do so from About.

### Automatic StoreKit Prompt

- Protocol: `RetroRacing/RetroRacingShared/Services/Protocols/RatingService.swift`
- Implementation: `RetroRacing/RetroRacingShared/Services/Implementations/StoreReviewService.swift`
- Platform presenter: `RatingServiceProvider` implementations per target.

`StoreReviewService` triggers the native prompt when all conditions pass:

1. The user has improved personal best score at least **3** times in the current app version.
2. The user has **not** already been prompted for the current app version.
3. At least **90 days** have passed since the last prompt.

This runs the same way for free and Unlimited Plays users — the native prompt is timed around a
satisfying gameplay moment (not tied to a visible on-screen ask), so it is **not** suppressed for
premium purchasers. Only the home-screen menu CTA is exclusive to free users (see below).

## Gameplay Integration

- `GameViewModel+Gameplay.handleCollision()` checks game over flow.
- When lives reach zero:
  - Score is submitted to leaderboard.
  - Best score is updated through `HighestScoreStore.updateIfHigher`.
  - If best score improved, set a one-shot flag for game-over presentation.
- When the game-over modal (`GameOverView`) appears on non-watch platforms:
  - `ratingService.recordBestScoreImprovementAndRequestIfEligible()` is called once if that one-shot flag is set.

This ties automatic prompt timing to moments where the user is likely satisfied.

## Unlimited Plays Menu Exclusion

Users who have purchased Unlimited Plays have already supported the game, so the home-screen
menu should not visibly ask them to also rate it:

- **Menu engagement CTA:** `MenuView.shouldShowRateButtonPolicy` hides the `menu_rate_game`
  button when `hasPremiumAccessForGating` is `true` (including cached premium on launch).
  Support uses `shouldShowFreeTierAffordances` so free CTAs are withheld until StoreKit confirms
  the user is not premium.
- **Native StoreKit prompt:** unaffected — still eligible for premium users (see "Automatic
  StoreKit Prompt" above), since it is not a visible, repeated on-screen ask.
- **About screen:** unaffected — the About screen's Rate button (`about_rate_title`) is always
  visible so a premium user can still rate voluntarily if they want to.

## Persistence Keys

`StoreReviewService` persists prompt state in `UserDefaults`:

- `StoreReview.lastPromptDate`
- `StoreReview.bestScoreImprovements_<appVersion>`
- `StoreReview.hasRatedVersion_<appVersion>`

## Menu Engagement Block

The menu shows an engagement section below the Play and Leaderboard buttons when the rate
button and/or support button should be visible (`showRateButton || showSupportButton`, both
computed via their respective policy functions on `MenuView`):

- **Prompt text** varies by context:
  - Free user (support button visible): `"menu_engagement_prompt"` — "Enjoying the game? You can help RetroRapid!"
  - Paid user (support button hidden, rate button still resolving): `"menu_engagement_prompt_rate_only"` — "Enjoying the game?"
- **Rate button** (`"menu_rate_game"`): "Rate it" — opens App Store write-review URL. Hidden when
  `hasPremiumAccessForGating` is `true` (`shouldShowRateButtonPolicy`).
- **Support button** (`"menu_support_game"`): "Back development" — opens paywall. Shown only when
  `shouldShowFreeTierAffordances` is `true`.

Unlimited Plays purchasers see neither button. Free-tier CTAs are withheld until live entitlements
resolve, so premium users never flash Support/Rate prompts on cold launch.

## tvOS Notes

- tvOS keeps `showRateButton = false` in menu parity flow, so the universal menu engagement CTA block is hidden.
- tvOS `RatingServiceProviderTvOS` remains a no-op for native in-app review.

## Testing Strategy

Unit tests in `RetroRacing/RetroRacingSharedTests/StoreReviewServiceTests.swift` validate:

- Manual native prompt request still calls provider and records prompt date.
- Two best-score improvements do not trigger prompt.
- Third improvement triggers one prompt.
- Additional improvements after prompt do not trigger extra prompts in same version.

Unit tests in `RetroRacing/RetroRacingSharedTests/GameViewModelTests.swift` validate:

- `MenuView.shouldShowRateButtonPolicy` hides the rate button when `hasPremiumAccessForGating`
  is `true`.
- `MenuView.shouldShowSupportButtonPolicy` shows Support only when `shouldShowFreeTierAffordances`
  is `true`.

## References

- `about_screen.md`
- `testing.md`
