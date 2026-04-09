# Achievements / Challenges Infrastructure

## Overview

RetroRacing tracks challenge progress locally and reports achieved challenges to Game Center achievements when authentication is available.

Current scope:

1. Persist challenge progress locally.
2. Backfill baseline progress from existing best-score data.
3. Record completed-run progress and telemetry (control usage + GAAD assistive eligibility).
4. Report newly achieved challenges to Game Center with replay sync on startup/auth changes.
5. Keep local snapshot as source of truth for idempotent, non-blocking reporting.

## Challenge Catalog

Achievement IDs use the main app bundle identifier plus `.ach` (for example `com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0100`). Persisted snapshots decode legacy `ach.*` strings automatically.

### Streak (single-run overtakes)

User-facing batch name: **Streak**.

Thresholds:

1. 100
2. 200
3. 500
4. 600
5. 700
6. 800

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

1. GAAD Assistive Week (`com.accessibilityUpTo11.RetroRacing.ach.event.gaad.assistive`)
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

## Architecture

### Shared models

1. `ChallengeIdentifier`
2. `ChallengeDefinition`
3. `ChallengeProgressSnapshot`
4. `ChallengeControlInput`
5. `ChallengeAssistiveTechnology`
6. `RunInputTelemetry`

### Shared services

1. `ChallengeProgressService`
2. `ChallengeProgressStore`
3. `ChallengeProgressReporter`

Implementations:

1. `LocalChallengeProgressService`
2. `UserDefaultsChallengeProgressStore`
3. `NoOpChallengeProgressReporter` (fallback/tests)
4. `GameCenterChallengeProgressReporter` (production reporting)

## Backfill Rules

One-time backfill (`backfillVersion = 1`) seeds progress from existing per-difficulty best scores:

1. Per-run baseline = max of cruise/fast/rapid best.
2. Cumulative baseline = sum of cruise/fast/rapid bests.

Backfill is idempotent:

1. Runs once per version marker.
2. Never regresses already higher local challenge progress.

## Runtime Recording Rules

1. Progress is recorded on completed game over only.
2. Shared `GameViewModel` records completed-run overtakes, control telemetry, completion date, and assistive telemetry when lives reach zero.
3. watchOS `WatchGameView` records using the same challenge service contract.
4. Control and assistive telemetry are per-run and reset on run start/restart.
5. VoiceOver control challenge still unlocks through `ChallengeControlInput.voiceOver` latched during completed runs.
6. GAAD challenge uses run completion date + assistive telemetry and then persists a one-time completion signal.

## Game Center Reporting & Replay

1. Newly achieved challenge IDs are reported immediately to Game Center as 100% `GKAchievement` progress.
2. Replay sync sends the full achieved-ID set from local snapshot (source of truth).
3. Replay triggers:
   - post-backfill at startup
   - Game Center authentication state change callbacks
4. Reporting never blocks gameplay and tolerates offline/auth failures via later replay.
5. Game Center completion banners are enabled when achievements are reported.

## Game-Over Unlock UI

1. When a completed run unlocks one or more new challenges, `GameOverView` presents `ChallengeUnlockView` as a regular sheet stacked above the game-over sheet.
2. The challenge sheet lists up to 3 newly unlocked challenge titles and shows a `+N more` summary when needed.
3. Challenge artwork uses challenge-asset resolution by challenge identifier with `ChallengeDefault` as fallback.
4. The challenge sheet includes:
   - primary `Done` action
   - secondary `Other challenges` action that opens the Game Center challenges surface via `GKAccessPoint` on iOS/macOS
   - on iOS/iPadOS/visionOS, actions are rendered in a bottom overlay action bar that ignores bottom safe area, uses a concentric rounded shape, and applies iOS glass effect with platform fallback
5. Both game-over and challenge sheets expose a top-right Share action that exports content-only PNG snapshots (no action buttons/toolbars) in a 4:3 social format (including macOS).
6. Share rendering adapts to the current light/dark color scheme.
7. This unlock-modal behavior is available on Universal platforms, including macOS.
8. Share snapshots use a single integrated layout (no inner rounded card container).
9. Share snapshots include the localized game name at the top, styled with the app font pipeline in `.largeTitle` and `.primary`, matching menu branding.
10. The challenge unlock sheet supports pull-down interactive dismissal.

## Debug QA Panel

Debug builds expose a GAAD challenge QA panel in Settings:

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
   - a forced challenge picker that injects a selected challenge into game-over unlock UI for QA (local UI-only; no challenge submission/reporting)
   - a SpriteKit diagnostics toggle (`showsFPS` + `showsNodeCount`) for runtime performance checks

## Logging

Challenge logs use `AppLog.challenge` with emoji prefix `🏅` for easy console filtering.

## App Store Connect Setup (Manual)

Detailed rollout runbook:

1. See `Requirements/challenges_rollout_checklist.md` for per-bundle capability + ASC release steps.
2. Canonical achievement IDs are defined by `ChallengeIdentifier`/`ChallengeCatalog` in shared code.
3. Keep this document focused on product/runtime behavior; keep release-ops details (IDs, ASC localization payload, and rollout checks) in `Requirements/challenges_rollout_checklist.md`.
