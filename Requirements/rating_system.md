# Rating System

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Manual App Store review links, automatic StoreKit prompt timing, menu CTA visibility, and rating persistence.
- **Must not break:** Review URL uses App Store ID `6758641625`; native prompt is version-throttled; menu rating/support CTAs do not flash for Unlimited Plays users.
- **Key files:** `AppStoreReviewURL`, `RatingService`, `StoreReviewService`, `MenuView`, `AboutView`.

## Behavior Contract

- Manual Rate buttons open `https://apps.apple.com/app/id6758641625?action=write-review`.
- Menu Rate CTA is hidden when `hasPremiumAccessForGating` is true.
- About Rate button is always available for voluntary rating.
- Native StoreKit prompt is automatic and tied to positive gameplay timing, not manual taps.
- tvOS keeps the menu engagement block hidden and uses a no-op rating provider.

## Automatic Prompt Eligibility

`StoreReviewService` requests the native prompt only when all conditions pass:

- at least three personal-best improvements in the current app version
- no prompt already shown for the current app version
- at least 90 days since the last prompt

## Persistence

- `StoreReview.lastPromptDate`
- `StoreReview.bestScoreImprovements_<appVersion>`
- `StoreReview.hasRatedVersion_<appVersion>`

## Menu Engagement

- The engagement block appears only when Rate or Support should be visible.
- Support uses `shouldShowFreeTierAffordances`.
- Rate uses `hasPremiumAccessForGating`.
- Free-tier CTAs are withheld until StoreKit resolves so returning purchasers do not see a cold-launch flash.

## Testing

- Unit tests cover prompt thresholds, per-version throttling, prompt-date persistence, menu rate/support policies, and About review URL routing.
