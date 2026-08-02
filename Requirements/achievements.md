# Achievements

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Local achievement progress, Game Center reporting, catalog IDs, metadata fetch, unlock UI, and replay sync.
- **Must not break:** Local snapshot is source of truth; IDs use `com.accessibilityUpTo11.RetroRacing.achievement.` prefix; reporting is idempotent and non-blocking; Game Center point budget stays under 1,000.
- **Key files:** `AchievementIdentifier`, `AchievementCatalog`, `AchievementProgressService`, `AchievementMetadataService`, `GameOverView`, `AchievementUnlockView`.

## Catalog

- Current set: 22 achievements, 700 points total, 300 points reserved.
- ID prefix: `com.accessibilityUpTo11.RetroRacing.achievement.`
- IDs are immutable once created in App Store Connect and must stay under 100 characters.
- Families:
  - Streak: single-run overtakes at 100, 200, 300, 400, 500, 600, 700, 800.
  - Overlander: lifetime overtakes at 1K, 5K, 10K, 20K, 50K, 100K, 200K.
  - Controls: tap, swipe, keyboard, VoiceOver, Digital Crown, game controller.
  - Event: GAAD Assistive Week.
- Hidden achievements: Streak 600/700/800, Overlander 200K, GAAD Assistive Week.

## Runtime Recording

- Progress is recorded only on completed game over.
- Shared gameplay records completed-run overtakes, control telemetry, completion date, and assistive telemetry when lives reach zero.
- watchOS records through the same achievement service contract.
- Control and assistive telemetry reset at run start/restart.
- VoiceOver control achievement unlocks when VoiceOver was active during a completed run.
- GAAD Assistive Week unlocks once when a run completes during the local GAAD week and qualifying assistive technology is active.
- GAAD week is the Monday-Sunday week containing the third Thursday of May in local device time.
- v1 qualifying assistive technologies:
  - Universal/tvOS/macOS/visionOS: VoiceOver and Switch Control.
  - watchOS: VoiceOver only.

## Backfill and Reporting

- Backfill version 1 seeds progress from existing per-difficulty best scores:
  - single-run baseline: max of Cruise/Fast/Rapid bests
  - cumulative baseline: sum of Cruise/Fast/Rapid bests
- Backfill is idempotent and never regresses higher local progress.
- Newly achieved IDs are reported to Game Center at 100% progress.
- Replay sync sends the full achieved-ID set from the local snapshot after startup/backfill and Game Center authentication changes.
- Reporting failures never block gameplay; later replay handles offline or unauthenticated paths.

## Metadata and Unlock UI

- `AchievementMetadataService` prefers live Game Center title, description, and artwork.
- Local strings and bundled `AchievementDefault` artwork are the fallback for unauthenticated, offline, error, or not-yet-loaded states.
- `AchievementUnlockView` may show up to three newly unlocked achievements plus a `+N more` summary.
- The unlock sheet can open Game Center achievements where platform presentation supports it.
- Game-over and achievement share actions export content-only 4:3 PNG snapshots without action chrome and adapt to light/dark appearance.

## Debug QA

- DEBUG Settings expose GAAD qualification diagnostics and a forced achievement picker.
- Forced achievement selection is UI-only for game-over unlock testing and must not submit/report achievements.
- SpriteKit diagnostics toggles may live in the same Debug area but are not part of achievement progress.

## Operations

- App Store Connect rollout, bundle capability checks, localized catalogs, and upload commands live in [AppStore/game-center/achievements-rollout.md](../AppStore/game-center/achievements-rollout.md).
- Achievement logs follow [logging.md](logging.md), domain `ACHIEVEMENT`.

## Testing

- Unit tests cover backfill idempotence, completed-run updates, control telemetry, GAAD week windows, assistive qualification, replay sync, metadata fallback/cache behavior, unlock-modal state, forced debug UI injection, and share snapshot rendering.
