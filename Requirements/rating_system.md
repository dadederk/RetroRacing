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
- Menu button (`MenuView`) opens the URL via `openURL`.
- About screen button (`AboutView`) opens the same URL via `openURL`.

### Automatic StoreKit Prompt

- Protocol: `RetroRacing/RetroRacingShared/Services/Protocols/RatingService.swift`
- Implementation: `RetroRacing/RetroRacingShared/Services/Implementations/StoreReviewService.swift`
- Platform presenter: `RatingServiceProvider` implementations per target.

`StoreReviewService` triggers the native prompt when all conditions pass:

1. The user has improved personal best score at least **3** times in the current app version.
2. The user has **not** already been prompted for the current app version.
3. At least **90 days** have passed since the last prompt.

## Gameplay Integration

- `GameViewModel+Gameplay.handleCollision()` checks game over flow.
- When lives reach zero:
  - Score is submitted to leaderboard.
  - Best score is updated through `HighestScoreStore.updateIfHigher`.
  - If best score improved, set a one-shot flag for game-over presentation.
- When the game-over modal (`GameOverView`) appears on non-watch platforms:
  - `ratingService.recordBestScoreImprovementAndRequestIfEligible()` is called once if that one-shot flag is set.

This ties automatic prompt timing to moments where the user is likely satisfied.

## Persistence Keys

`StoreReviewService` persists prompt state in `UserDefaults`:

- `StoreReview.lastPromptDate`
- `StoreReview.bestScoreImprovements_<appVersion>`
- `StoreReview.hasRatedVersion_<appVersion>`

## tvOS Notes

- tvOS keeps `showRateButton = false` in menu parity flow.
- tvOS `RatingServiceProviderTvOS` remains a no-op for native in-app review.

## Testing Strategy

Unit tests in `RetroRacing/RetroRacingSharedTests/StoreReviewServiceTests.swift` validate:

- Manual native prompt request still calls provider and records prompt date.
- Two best-score improvements do not trigger prompt.
- Third improvement triggers one prompt.
- Additional improvements after prompt do not trigger extra prompts in same version.

## References

- `about_screen.md`
- `testing.md`
