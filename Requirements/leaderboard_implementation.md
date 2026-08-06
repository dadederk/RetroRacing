# Leaderboards

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Game Center leaderboards per platform and difficulty, friend leaderboard snapshots, pending score replay, and watch fallback relay.
- **Must not break:** No `#if os()` in services; platform configs delegate to `LeaderboardIDCatalog`; debug builds do not submit scores unless explicitly allowed; watch relay submits to watch leaderboard IDs.
- **Key files:** `LeaderboardIDCatalog`, `LeaderboardConfiguration*`, `GameCenterService`, `PendingLeaderboardScoreStore`, `BestScoreSyncService`.

## Leaderboard Scope

- Leaderboards are per platform and speed: Cruise, Fast, Rapid.
- Assistive technology users share the same platform/speed leaderboards.
- Current App Store Connect status: iPhone, iPad, macOS, tvOS, and watchOS boards are created and released. The three tvOS boards remain catalogued for idempotent validation and localization updates from their matching iPhone templates. visionOS IDs remain configured in code for later setup.
- Speed pacing:
  - Rapid: baseline (`initialInterval: 0.6`)
  - Fast: middle pace (`initialInterval: 0.96`)
  - Cruise: slowest (`initialInterval: 1.44`)

## ID Contract

| Platform | Cruise | Fast | Rapid |
|---|---|---|---|
| iPhone | `bestios001cruise` | `bestios001fast` | `bestios001test` |
| iPad | `bestipad001cruise` | `bestipad001fast` | `bestipad001test` |
| macOS | `bestmacos001cruise` | `bestmacos001fast` | `bestmacos001test` |
| tvOS | `besttvos001cruise` | `besttvos001fast` | `besttvos001` |
| watchOS | `bestwatchos001cruise` | `bestwatchos001fast` | `bestwatchos001test` |

- `LeaderboardIDCatalog` is the single source of truth for platform/speed IDs.
- Platform-specific `LeaderboardConfiguration` types must delegate to the catalog.
- `LeaderboardConfigurationWatchOS` lives in shared code so direct watch submit and iPhone relay use the same mapping.

## Runtime Behavior

- `GameCenterService` receives `LeaderboardConfiguration`, `GameCenterFriendSnapshotServicing`, build-mode flag, and optional debug-submit override through initialization.
- Debug builds skip score submission by default and log the skip; diagnostics may explicitly enable debug submission at the composition root.
- If the player is unauthenticated, pending score storage keeps only the best pending score per difficulty.
- Pending scores flush on Game Center authentication and lifecycle triggers.
- If read-after-write verification cannot confirm remote persistence, the score is re-queued.
- `BestScoreSyncService` syncs the active platform/speed remote best into the local highest-score store when available.

## Presentation

- iOS, tvOS, and macOS keep the ambient `GKAccessPoint` hidden and open the selected-speed leaderboard explicitly through it.
- iOS and tvOS automatically request authentication once per menu instance; dismissing the system authentication UI must not create a presentation loop.
- watchOS has no in-app leaderboard sheet; it submits scores and tells players to view leaderboards on iPhone or iPad.
- Views should depend on leaderboard services, not direct GameKit APIs, except narrow presentation surfaces.

## watchOS Fallback Relay

- watchOS submits directly on game over.
- When a watch score becomes a new local best, it also relays the best score to iPhone via WatchConnectivity.
- iPhone stores one pending max per speed and submits to watchOS leaderboard IDs.
- Verification is single-shot per natural trigger: relay received, app active/launch, or auth-state change.

## Friend Social Milestones

- Live gameplay can show up to two upcoming friend markers.
- Game over can show the next friend ahead and friends overtaken in that run.
- Baseline uses remote Game Center best when available, with local best fallback.
- Social UI is hidden when friend data is unavailable or empty.
- watchOS is out of scope for v1 friend milestone UI.

## Operations

- App Store Connect leaderboard creation and localization live in [AppStore/game-center/README.md](../AppStore/game-center/README.md).
- `./retrorapid asc game-center --leaderboards-only --ensure-leaderboards` creates missing catalogued tvOS boards, validates existing configurations against their templates, ensures live releases, and uploads localizations. Always inspect its `--dry-run` first.
- Do not change a leaderboard ID in code without creating the corresponding ASC leaderboard and retiring the old one intentionally.
- Logs follow [logging.md](logging.md), domain `LEADERBOARD`.

## Testing

- Unit tests cover platform/speed ID mapping, pending score max retention, debug submission guard, auth-triggered flushing, read-after-write requeue, best-score sync, watch relay parsing/max guard, friend snapshot normalization, and social milestone selection.
- Sandbox/manual diagnostics should focus on authentication failures, ASC visibility/configuration mismatches, and watchOS `GKErrorGameUnrecognized` cases.
