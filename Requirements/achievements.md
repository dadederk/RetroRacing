# Achievements Infrastructure

## Overview

RetroRacing tracks achievement progress locally and reports achieved IDs to Game Center when authentication is available.

Current scope:

1. Persist achievement progress locally.
2. Backfill baseline progress from existing best-score data.
3. Record completed-run progress and telemetry (control usage + GAAD assistive eligibility).
4. Report newly achieved achievements to Game Center with replay sync on startup/auth changes.
5. Keep local snapshot as source of truth for idempotent, non-blocking reporting.

## Achievement Catalog

Achievement IDs use the canonical prefix `com.accessibilityUpTo11.RetroRacing.achievement.` (for example `com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0100`).

ID constraints:

1. App Store Connect achievement IDs are limited to 100 characters (single-byte assumption).
2. IDs are treated as immutable once created in App Store Connect.
3. Current longest ID is `com.accessibilityUpTo11.RetroRacing.achievement.control.gamecontroller` (70 characters), within limits.

### Streak (single-run overtakes)

User-facing batch name: **Streak**.

Thresholds (all 8 are now defined in `AchievementIdentifier` and `AchievementCatalog`):

1. 100
2. 200
3. 300
4. 400
5. 500
6. 600
7. 700
8. 800

### Overlander (lifetime overtakes)

User-facing batch name: **Overlander**.

Thresholds:

1. 1,000
2. 5,000
3. 10,000
4. 20,000
5. 50,000
6. 100,000
7. 200,000

### Control-Based

Unlocked when used at least once in a completed run:

1. Tap
2. Swipe
3. Keyboard
4. VoiceOver (VoiceOver ON at any point during completed run)
5. Digital Crown
6. Game Controller

### Event-Based

1. GAAD Assistive Week (`com.accessibilityUpTo11.RetroRacing.achievement.event.gaad.assistive`)
   - One-time lifetime unlock.
   - Requirement: complete a run during GAAD week while an assistive technology is active.
   - GAAD week definition: Monday-Sunday week containing the third Thursday of May, in local device time.
   - 2026 GAAD week: 2026-05-18 00:00:00 to 2026-05-24 23:59:59 (local time).

Assistive technologies used for this rule in v1:

1. VoiceOver
2. Switch Control

Not included in v1:

1. Full Keyboard Access

watchOS GAAD rule in v1:

1. VoiceOver-only qualification path.

## Point Values

Game Center achievement points follow two constraints: maximum 100 pts per achievement, maximum 1,000 pts across all achievements. The current 22 achievements spend 700 pts, leaving 300 pts in reserve for future additions.

### Streak

| Achievement | Points |
| --- | --- |
| Streak 100 | 5 |
| Streak 200 | 5 |
| Streak 300 | 10 |
| Streak 400 | 15 |
| Streak 500 | 20 |
| Streak 600 | 35 |
| Streak 700 | 65 |
| Streak 800 | 100 |
| **Family total** | **255** |

Points increase exponentially from Streak 500 onward to reflect the compounding difficulty: the game speed increases every 100 overtakes, making each upper tier significantly harder than the last.

Visibility: Streak 600, Streak 700, and Streak 800 are hidden achievements in App Store Connect. They are not shown to the player until unlocked.

### Overlander

| Achievement | Points |
| --- | --- |
| Overlander 1K | 5 |
| Overlander 5K | 10 |
| Overlander 10K | 20 |
| Overlander 20K | 30 |
| Overlander 50K | 50 |
| Overlander 100K | 75 |
| Overlander 200K | 100 |
| **Family total** | **290** |

Visibility: Overlander 200K is a hidden achievement in App Store Connect. It is not shown to the player until unlocked.

### Control-Based

| Achievement | Points |
| --- | --- |
| Tap Controls | 5 |
| Swipe Controls | 5 |
| Keyboard Controls | 10 |
| Digital Crown Controls | 15 |
| Game Controller Controls | 15 |
| VoiceOver Controls | 30 |
| **Family total** | **80** |

VoiceOver is weighted highest in the family to reflect the game's accessibility identity.

### Event-Based

| Achievement | Points |
| --- | --- |
| GAAD Assistive Week | 75 |
| **Family total** | **75** |

Elevated above a standard unlock to reflect its time-limited and assistive-technology-required nature.

Visibility: GAAD Assistive Week is a hidden achievement in App Store Connect. It is not shown to the player until unlocked.

### Budget Summary

| Family | Achievements | Points |
| --- | --- | --- |
| Streak | 8 | 255 |
| Overlander | 7 | 290 |
| Control | 6 | 80 |
| Event | 1 | 75 |
| **Total spent** | **22** | **700** |
| **Reserve (future achievements)** | — | **300** |

## Architecture

### Shared models

1. `AchievementIdentifier`
2. `AchievementDefinition`
3. `AchievementProgressSnapshot`
4. `AchievementControlInput`
5. `AchievementAssistiveTechnology`
6. `RunAchievementTelemetry`
7. `AchievementMetadata`

### Shared services

1. `AchievementProgressService`
2. `AchievementProgressStore`
3. `AchievementProgressReporter`
4. `AchievementMetadataService`

Implementations:

1. `LocalAchievementProgressService`
2. `UserDefaultsAchievementProgressStore`
3. `NoOpAchievementProgressReporter` (fallback/tests)
4. `GameCenterAchievementProgressReporter` (production reporting)
5. `GameCenterAchievementMetadataService` (production metadata fetch from GC)
6. `NoOpAchievementMetadataService` (fallback/tests)

## Backfill Rules

One-time backfill (`backfillVersion = 1`) seeds progress from existing per-difficulty best scores:

1. Per-run baseline = max of cruise/fast/rapid best.
2. Cumulative baseline = sum of cruise/fast/rapid bests.

Backfill is idempotent:

1. Runs once per version marker.
2. Never regresses already higher local achievement progress.

## Runtime Recording Rules

1. Progress is recorded on completed game over only.
2. Shared `GameViewModel` records completed-run overtakes, control telemetry, completion date, and assistive telemetry when lives reach zero.
3. watchOS `WatchGameView` records using the same achievement service contract.
4. Control and assistive telemetry are per-run and reset on run start/restart.
5. VoiceOver control achievement still unlocks through `AchievementControlInput.voiceOver` latched during completed runs.
6. GAAD achievement uses run completion date + assistive telemetry and then persists a one-time completion signal.

## Game Center Reporting & Replay

1. Newly achieved achievement IDs are reported immediately to Game Center as 100% `GKAchievement` progress.
2. Replay sync sends the full achieved-ID set from local snapshot (source of truth).
3. Replay triggers:
   - post-backfill at startup
   - Game Center authentication state change callbacks
4. Reporting never blocks gameplay and tolerates offline/auth failures via later replay.
5. Game Center completion banners are enabled when achievements are reported.

## Game Center Metadata (Title & Description)

The unlock UI prefers live data from Game Center over local fallbacks so that achievement titles
and descriptions can be updated in App Store Connect without requiring an app release.

1. `AchievementMetadataService` protocol — `fetchAllMetadata() async -> [String: AchievementMetadata]`.
2. `GameCenterAchievementMetadataService` — actor-based implementation that calls
   `GKAchievementDescription.loadAchievementDescriptions` on first use and caches the result for
   the process lifetime. Concurrent callers share a single in-flight `Task`.
3. Falls back to local `AchievementIdentifier.localizedTitle` / generic modal strings when:
   - Player is not authenticated.
   - Game Center returns an error.
   - Metadata has not loaded yet (shows local strings until the async fetch completes).
4. Injected via the SwiftUI environment using `EnvironmentValues.achievementMetadataService`.
   The default value is `nil`; views fall back to local strings when not set.
5. `AchievementUnlockView` triggers `fetchAllMetadata()` in a `.task` on appear and stores the
   result in `@State`. The cache means the call is instant on repeat presentations.

## Game-Over Unlock UI

1. When a completed run unlocks one or more new achievements, `GameOverView` presents `AchievementUnlockView` as a regular sheet stacked above the game-over sheet.
2. The achievement sheet lists up to 3 newly unlocked achievement titles and shows a `+N more` summary when needed.
3. Achievement artwork uses achievement-asset resolution by achievement identifier with `AchievementDefault` as fallback.
4. The achievement sheet includes:
   - primary `Done` action
   - secondary `Other achievements` action that opens the Game Center achievements surface via `GKAccessPoint` on iOS/macOS
   - on iOS/iPadOS/visionOS, actions are rendered in a bottom overlay action bar that ignores bottom safe area, uses a concentric rounded shape, and applies iOS glass effect with platform fallback
5. Both game-over and achievement sheets expose a top-right Share action that exports content-only PNG snapshots (no action buttons/toolbars) in a 4:3 social format (including macOS).
6. Share rendering adapts to the current light/dark color scheme.
7. This unlock-modal behavior is available on Universal platforms, including macOS.
8. Share snapshots use a single integrated layout (no inner rounded card container).
9. Share snapshots include the localized game name at the top, styled with the app font pipeline in `.largeTitle` and `.primary`, matching menu branding.
10. The achievement unlock sheet supports pull-down interactive dismissal.

## Debug QA Panel

Debug builds expose a GAAD achievement QA panel in Settings:

1. Universal/tvOS/macOS/visionOS: qualification mode shown as VoiceOver + Switch Control (v1).
2. watchOS: qualification mode shown as VoiceOver-only (v1).
3. Panel shows live:
   - current local time
   - computed GAAD week window for current year
   - whether current time is inside GAAD week
   - active assistive technologies detected by telemetry
   - whether a run completed now would qualify
   - local GAAD completion signal and achievement state
4. Debug settings also include:
   - a forced achievement picker that injects a selected achievement into game-over unlock UI for QA (local UI-only; no achievement submission/reporting)
   - a SpriteKit diagnostics toggle (`showsFPS` + `showsNodeCount`) for runtime performance checks

## Logging

Achievement logs follow the canonical contract in [logging.md](logging.md):
- Primary domain: `ACHIEVEMENT` (`🏅`), optionally paired with `LEADERBOARD` (`🏆`) for Game Center reporting paths.
- Structured shape: `<emoji> <DOMAIN> <EVENT_NAME>: outcome=<state> key=value ...`
- Use `reason=` on blocked/failed/skipped paths.
- Use redaction helpers for sensitive metadata (never raw player names or full URLs).

## App Store Connect Setup (Manual)

All 22 achievements are created in App Store Connect in English US. As of April 2026 this is the only configured language; additional locales can be added in ASC without requiring an app release, and the app will pick them up automatically via `AchievementMetadataService`.

Hidden achievements (not shown until unlocked):
- Streak 600, Streak 700, Streak 800
- Overlander 200K
- GAAD Assistive Week

Detailed rollout runbook:

1. See `Requirements/achievements_rollout_checklist.md` for per-bundle capability + ASC release steps.
2. Canonical achievement IDs are defined by `AchievementIdentifier`/`AchievementCatalog` in shared code.
3. Keep this document focused on product/runtime behavior; keep release-ops details (IDs, ASC localization payload, and rollout checks) in `Requirements/achievements_rollout_checklist.md`.
