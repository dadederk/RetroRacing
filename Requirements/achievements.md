# Achievements / Challenges Infrastructure

## Overview

RetroRacing tracks local challenge progress now, before Game Center achievements are created in App Store Connect. This enables later retroactive awarding once ASC entries exist.

Current scope is local progress only:

1. Persist challenge progress locally.
2. Backfill baseline progress from existing best-score data.
3. Record completed-run progress and control usage telemetry.
4. Keep reporting path abstracted behind a no-op reporter until ASC setup.

## Challenge Catalog

### Overtakes in One Run

Thresholds:

1. 100
2. 200
3. 500
4. 600
5. 700
6. 800

### Total Overtakes (Cumulative)

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

## Architecture

### Shared models

1. `ChallengeIdentifier`
2. `ChallengeDefinition`
3. `ChallengeProgressSnapshot`
4. `ChallengeControlInput`
5. `RunInputTelemetry`

### Shared services

1. `ChallengeProgressService`
2. `ChallengeProgressStore`
3. `ChallengeProgressReporter`

Implementations:

1. `LocalChallengeProgressService`
2. `UserDefaultsChallengeProgressStore`
3. `NoOpChallengeProgressReporter`

## Backfill Rules

One-time backfill (`backfillVersion = 1`) seeds progress from existing per-difficulty best scores:

1. Per-run baseline = max of cruise/fast/rapid best.
2. Cumulative baseline = sum of cruise/fast/rapid bests.

Backfill is idempotent:

1. Runs once per version marker.
2. Never regresses already higher local challenge progress.

## Runtime Recording Rules

1. Progress is recorded on completed game over only.
2. Shared `GameViewModel` records completed-run overtakes and control telemetry when lives reach zero.
3. watchOS `WatchGameView` records using the same challenge service contract.
4. Control telemetry is per-run and resets on run start/restart.

## Logging

Challenge logs use `AppLog.challenge` with emoji prefix `🏅` for easy console filtering.

## Future ASC Integration

When ASC achievements are created:

1. Add a Game Center-backed `ChallengeProgressReporter`.
2. Map local `ChallengeIdentifier` values to ASC achievement IDs.
3. Replay locally achieved challenge IDs to Game Center once authenticated.
4. Keep local progress as source of truth for idempotent sync.
