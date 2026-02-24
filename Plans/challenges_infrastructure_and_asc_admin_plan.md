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
3. Prefix with `ach.`.
4. Use functional grouping:
   - `ach.run.overtakes.*`
   - `ach.total.overtakes.*`
   - `ach.control.*`

## 6.2 Proposed Achievement Metadata Matrix

Notes:

1. `ASC ID` should be the final `GKAchievement` identifier.
2. `Reference Name` is internal-facing in ASC.
3. `Points` are suggested and can be tuned.
4. `Hidden` recommended `No` for all in this first version.

| Local Key | ASC ID | Reference Name | Type | Threshold / Rule | Suggested Points | Hidden |
| --- | --- | --- | --- | --- | --- | --- |
| run_100 | ach.run.overtakes.0100 | Run Overtakes 100 | Overtakes per run | >= 100 in one completed run | 5 | No |
| run_200 | ach.run.overtakes.0200 | Run Overtakes 200 | Overtakes per run | >= 200 in one completed run | 10 | No |
| run_500 | ach.run.overtakes.0500 | Run Overtakes 500 | Overtakes per run | >= 500 in one completed run | 20 | No |
| run_600 | ach.run.overtakes.0600 | Run Overtakes 600 | Overtakes per run | >= 600 in one completed run | 20 | No |
| run_700 | ach.run.overtakes.0700 | Run Overtakes 700 | Overtakes per run | >= 700 in one completed run | 20 | No |
| run_800 | ach.run.overtakes.0800 | Run Overtakes 800 | Overtakes per run | >= 800 in one completed run | 25 | No |
| total_1k | ach.total.overtakes.001k | Total Overtakes 1K | Cumulative overtakes | >= 1,000 lifetime | 10 | No |
| total_5k | ach.total.overtakes.005k | Total Overtakes 5K | Cumulative overtakes | >= 5,000 lifetime | 15 | No |
| total_10k | ach.total.overtakes.010k | Total Overtakes 10K | Cumulative overtakes | >= 10,000 lifetime | 20 | No |
| total_20k | ach.total.overtakes.020k | Total Overtakes 20K | Cumulative overtakes | >= 20,000 lifetime | 25 | No |
| total_50k | ach.total.overtakes.050k | Total Overtakes 50K | Cumulative overtakes | >= 50,000 lifetime | 30 | No |
| total_100k | ach.total.overtakes.100k | Total Overtakes 100K | Cumulative overtakes | >= 100,000 lifetime | 35 | No |
| total_200k | ach.total.overtakes.200k | Total Overtakes 200K | Cumulative overtakes | >= 200,000 lifetime | 40 | No |
| control_tap | ach.control.tap | Control Tap | Control method | Tap used in completed run | 5 | No |
| control_swipe | ach.control.swipe | Control Swipe | Control method | Swipe used in completed run | 5 | No |
| control_keyboard | ach.control.keyboard | Control Keyboard | Control method | Keyboard used in completed run | 5 | No |
| control_voiceover | ach.control.voiceover | Control VoiceOver | Accessibility/control | VoiceOver ON in completed run | 10 | No |
| control_crown | ach.control.crown | Control Digital Crown | Control method | Digital Crown used in completed run | 5 | No |

## 6.3 Localization Payload (EN / ES / CA)

Use these strings for ASC achievement localization.

### 6.3.1 Run Overtakes Achievements

| ASC ID | EN Title | EN Description | ES Title | ES Description | CA Title | CA Description |
| --- | --- | --- | --- | --- | --- | --- |
| ach.run.overtakes.0100 | First Hundred | Reach 100 overtakes in a single run. | Primer centenar | Alcanza 100 adelantamientos en una sola partida. | Primer centenar | Arriba a 100 avançaments en una sola partida. |
| ach.run.overtakes.0200 | Double Hundred | Reach 200 overtakes in a single run. | Doble centenar | Alcanza 200 adelantamientos en una sola partida. | Doble centenar | Arriba a 200 avançaments en una sola partida. |
| ach.run.overtakes.0500 | Five Hundred Run | Reach 500 overtakes in a single run. | Partida de 500 | Alcanza 500 adelantamientos en una sola partida. | Partida de 500 | Arriba a 500 avançaments en una sola partida. |
| ach.run.overtakes.0600 | Six Hundred Run | Reach 600 overtakes in a single run. | Partida de 600 | Alcanza 600 adelantamientos en una sola partida. | Partida de 600 | Arriba a 600 avançaments en una sola partida. |
| ach.run.overtakes.0700 | Seven Hundred Run | Reach 700 overtakes in a single run. | Partida de 700 | Alcanza 700 adelantamientos en una sola partida. | Partida de 700 | Arriba a 700 avançaments en una sola partida. |
| ach.run.overtakes.0800 | Eight Hundred Run | Reach 800 overtakes in a single run. | Partida de 800 | Alcanza 800 adelantamientos en una sola partida. | Partida de 800 | Arriba a 800 avançaments en una sola partida. |

### 6.3.2 Total Overtakes Achievements

| ASC ID | EN Title | EN Description | ES Title | ES Description | CA Title | CA Description |
| --- | --- | --- | --- | --- | --- | --- |
| ach.total.overtakes.001k | Road Starter | Reach 1,000 total overtakes. | Inicio en carretera | Alcanza 1.000 adelantamientos totales. | Inici en carretera | Arriba a 1.000 avançaments totals. |
| ach.total.overtakes.005k | Road Veteran | Reach 5,000 total overtakes. | Veterano de carretera | Alcanza 5.000 adelantamientos totales. | Veterà de carretera | Arriba a 5.000 avançaments totals. |
| ach.total.overtakes.010k | Road Specialist | Reach 10,000 total overtakes. | Especialista en carretera | Alcanza 10.000 adelantamientos totales. | Especialista de carretera | Arriba a 10.000 avançaments totals. |
| ach.total.overtakes.020k | Road Elite | Reach 20,000 total overtakes. | Élite en carretera | Alcanza 20.000 adelantamientos totales. | Elit de carretera | Arriba a 20.000 avançaments totals. |
| ach.total.overtakes.050k | Road Legend | Reach 50,000 total overtakes. | Leyenda de carretera | Alcanza 50.000 adelantamientos totales. | Llegenda de carretera | Arriba a 50.000 avançaments totals. |
| ach.total.overtakes.100k | Road Immortal | Reach 100,000 total overtakes. | Inmortal de carretera | Alcanza 100.000 adelantamientos totales. | Immortal de carretera | Arriba a 100.000 avançaments totals. |
| ach.total.overtakes.200k | Road Myth | Reach 200,000 total overtakes. | Mito de carretera | Alcanza 200.000 adelantamientos totales. | Mite de carretera | Arriba a 200.000 avançaments totals. |

### 6.3.3 Control-Based Achievements

| ASC ID | EN Title | EN Description | ES Title | ES Description | CA Title | CA Description |
| --- | --- | --- | --- | --- | --- | --- |
| ach.control.tap | Tap Driver | Complete a run using tap controls. | Piloto de toques | Completa una partida usando controles por toque. | Pilot de tocs | Completa una partida usant controls per toc. |
| ach.control.swipe | Swipe Driver | Complete a run using swipe controls. | Piloto de deslizamientos | Completa una partida usando deslizamientos. | Pilot de lliscaments | Completa una partida usant lliscaments. |
| ach.control.keyboard | Keyboard Driver | Complete a run using keyboard controls. | Piloto de teclado | Completa una partida usando teclado. | Pilot de teclat | Completa una partida usant teclat. |
| ach.control.voiceover | VoiceOver Driver | Complete a run while VoiceOver is enabled. | Piloto con VoiceOver | Completa una partida con VoiceOver activado. | Pilot amb VoiceOver | Completa una partida amb VoiceOver actiu. |
| ach.control.crown | Crown Driver | Complete a run using the Digital Crown. | Piloto de corona digital | Completa una partida usando la Corona Digital. | Pilot de corona digital | Completa una partida usant la Corona Digital. |

## 6.4 Suggested ASC Artwork Plan

1. Prepare one icon per achievement (18 total) as square PNG.
2. Use consistent visual families:
   - Run overtakes: same motif, increasing badge tiers.
   - Total overtakes: odometer/road progression motif.
   - Control achievements: icon per input method.
3. Keep sufficient contrast for accessibility.
4. Keep text out of icon artwork where possible.

## 6.5 ASC Creation Checklist (When We Decide to Publish)

1. Ensure Game Center is enabled on the app version/build in App Store Connect.
2. Create all achievement entries using the IDs in this document.
3. Fill reference name, points, hidden flag.
4. Add EN/ES/CA localizations (title + description).
5. Upload artwork for each entry.
6. Validate IDs exactly match client-side mapping constants.
7. Ship a build with reporter switched from no-op to Game Center implementation.
8. On first launch after that build, run retroactive sync from local snapshot to Game Center achievements.

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
