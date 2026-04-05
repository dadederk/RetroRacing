# Challenges Infrastructure Plan (Pre-App Store Connect) + Admin Setup Spec

## 1. Objective

Prepare challenge/achievement infrastructure now, without creating any Game Center achievements yet, so we can:

1. Start collecting progress immediately.
2. Backfill from already-stored best scores.
3. Retroactively unlock achievements later when App Store Connect configuration is done.

## 2. Scope for This Implementation Pass

1. Local challenge catalog and progress evaluator.
2. Persistent storage for challenge progress.
3. One-time migration/backfill from existing best scores.
4. Run-level telemetry for control-method challenges.
5. Game-over integration that records completed runs.
6. No-op reporter abstraction for future Game Center achievement reporting.

Out of scope:

1. Creating achievements in App Store Connect.
2. Submitting `GKAchievement` progress to Apple servers.
3. New player-facing achievements UI.

## 3. Locked Product Decisions

1. Per-game overtake thresholds: `100`, `200`, `500`, `600`, `700`, `800`.
2. Cumulative overtake thresholds: `1_000`, `5_000`, `10_000`, `20_000`, `50_000`, `100_000`, `200_000`.
3. Backfill source uses currently stored best score per difficulty:
   - Per-game baseline = `max(cruiseBest, fastBest, rapidBest)`
   - Cumulative baseline = `cruiseBest + fastBest + rapidBest`
4. Capture timing = completed game over only.
5. Control telemetry included now for: tap, swipe, keyboard, VoiceOver, Digital Crown.
6. Control challenge unlock rule = control used at least once in a completed run.
7. VoiceOver challenge unlock rule = VoiceOver ON at any point during a completed run.

## 4. Technical Architecture

## 4.1 New Domain Model

1. `ChallengeIdentifier`
2. `ChallengeDefinition`
3. `ChallengeCatalog`
4. `ChallengeProgressSnapshot`

`ChallengeProgressSnapshot` fields:

1. `bestRunOvertakes: Int`
2. `cumulativeOvertakes: Int`
3. `achievedChallengeIDs: Set<ChallengeIdentifier>`
4. `backfillVersion: Int?`

## 4.2 New Services

1. `ChallengeProgressService`
2. `ChallengeProgressStore`
3. `ChallengeProgressReporter`

Implementations:

1. `LocalChallengeProgressService`
2. `UserDefaultsChallengeProgressStore`
3. `NoOpChallengeProgressReporter`

## 4.3 Runtime Integration

1. Shared gameplay path (`GameViewModel` game-over flow) calls challenge service on completed run.
2. watchOS gameplay path (`WatchGameView` game-over flow) does the same.
3. Run telemetry is reset on new run start/restart.
4. Run telemetry is committed only once when lives reach zero.

## 4.4 Telemetry Mapping

1. `tap`: left/right tap actions.
2. `swipe`: drag gesture actions.
3. `keyboard`: hardware left/right arrow actions.
4. `digitalCrown`: crown-driven movement on watchOS.
5. `voiceOver`: sampled as ON during run (latched true once observed).

## 4.5 Backfill Flow

At app startup (composition root), run:

1. Load current challenge snapshot.
2. If `backfillVersion` missing, read existing best scores for cruise/fast/rapid.
3. Seed:
   - `bestRunOvertakes = max(currentValue, maxBest)`
   - `cumulativeOvertakes = max(currentValue, sumBest)`
4. Evaluate unlocked challenge IDs from seeded values.
5. Persist snapshot and set `backfillVersion = 1`.

Idempotence rules:

1. Backfill never lowers existing progress.
2. Backfill runs once per version marker.

## 5. Challenge Catalog (Canonical)

## 5.1 Overtakes in One Run

1. `100`
2. `200`
3. `500`
4. `600`
5. `700`
6. `800`

## 5.2 Total Overtakes (Cumulative)

1. `1_000`
2. `5_000`
3. `10_000`
4. `20_000`
5. `50_000`
6. `100_000`
7. `200_000`

## 5.3 Control-Based

1. Tap controls used in completed run.
2. Swipe controls used in completed run.
3. Keyboard controls used in completed run.
4. VoiceOver ON during completed run.
5. Digital Crown controls used in completed run.

## 6. App Store Connect Admin Section (Detailed)

Use this section later when we decide to create the achievements in ASC.

## 6.1 ID Naming Rules

1. Keep IDs stable forever once released.
2. Lowercase and dot-separated.
3. Prefix with `com.accessibilityUpTo11.RetroRacing.ach.`.
4. Use functional grouping:
   - `com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.*`
   - `com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.*`
   - `com.accessibilityUpTo11.RetroRacing.ach.control.*`
   - `com.accessibilityUpTo11.RetroRacing.ach.event.*`

## 6.2 Rollout Metadata (Canonical Location)

This plan intentionally omits long-lived release-ops payloads (full ASC ID matrix, localization payload tables, and per-bundle rollout checklists) to avoid duplication drift.

Canonical source for that material:

1. `Requirements/achievements.md` for runtime/challenge behavior.
2. `Requirements/challenges_rollout_checklist.md` for ASC + Developer Portal operational steps and localization payloads.

## 7. Rollout Notes for Future Game Center Reporting

1. Keep local challenge IDs as source of truth.
2. Add static mapping layer `localChallengeID -> ascAchievementID`.
3. On startup/game-over, compute newly achieved local IDs and report once.
4. Keep reporting idempotent and tolerant to offline/network failures.
5. Never block gameplay on reporting result.

## 8. Test Plan (Implementation Phase)

1. Catalog thresholds are exact.
2. One-time backfill uses max/sum rules and is idempotent.
3. Completed runs update cumulative + best-run correctly.
4. Control-based unlocks trigger only when control was used in completed run.
5. VoiceOver control unlock triggers when VoiceOver was ON during completed run.
6. Shared and watch game-over flows record progress exactly once.

## 9. Verification Commands

1. `xcrun xcodebuild test -scheme RetroRacingUniversal -destination "platform=iOS Simulator,name=iPhone 17 Pro" -only-testing:RetroRacingSharedTests CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
2. `xcrun xcodebuild test -scheme RetroRacingUniversal -destination "platform=iOS Simulator,name=iPhone 17 Pro" -only-testing:RetroRacingUniversalTests CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
3. `xcrun xcodebuild build -scheme RetroRacingUniversal -destination "platform=macOS" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
