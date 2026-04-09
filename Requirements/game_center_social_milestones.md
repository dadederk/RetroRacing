# Game Center Social Milestones

## Overview

RetroRacing adds friend-aware leaderboard context to live gameplay and game-over recap on **Universal + tvOS**:

1. During gameplay, the next one or two upcoming friend scores can be shown as in-race markers on the cars that correspond to score crossings.
2. On game over, the modal can show:
   - the next friend still ahead
   - friends overtaken in the just-finished run

watchOS is intentionally excluded in v1.

## Scope & Defaults

1. Platforms: iOS, iPadOS, macOS (Universal target) and tvOS.
2. Leaderboard domain: same selected difficulty leaderboard (`Cruise` / `Fast` / `Rapid`), all-time scope.
3. Baseline score for game-over social comparisons:
   - use remote Game Center best at run start when available
   - fallback to local best when remote best is unavailable
4. In-race markers:
   - compare against current run score (not baseline) so friend milestones can appear every run
   - show up to two upcoming markers at a time (nearest upcoming friend milestones)
   - hide marker if data is unavailable or there is no upcoming friend score
5. Data-availability behavior:
   - if auth/friend/avatar fetch fails, hide social UI (no global fallback UI)

## Architecture

### Service layer

`LeaderboardService` adds:

```swift
func fetchFriendLeaderboardSnapshot(for difficulty: GameDifficulty) async -> FriendLeaderboardSnapshot?
```

`GameCenterService` implementation:

1. Loads selected leaderboard by ID.
2. Reads local player remote best.
3. Loads friend entries (`playerScope: .friends`, `timeScope: .allTime`) with bounded pagination.
4. Normalizes entries (filter invalid rows, dedupe by player ID, sort by ascending score).
5. Hydrates a bounded set of avatar images from the sorted friend entries and caches PNG data in memory by `playerID`.

### Shared models

`RetroRacingShared/Services/Protocols/FriendLeaderboardModels.swift`:

1. `FriendLeaderboardSnapshot`
2. `FriendLeaderboardEntry`
3. `UpcomingFriendMilestone`
4. `GameOverFriendAheadSummary`
5. `GameOverOvertakenFriendSummary`

### Gameplay integration

`GameViewModel`:

1. Refreshes friend snapshot on run start/restart and difficulty changes.
2. Tracks run baseline (`remote best` first, then local fallback).
3. Maintains up to two upcoming milestones based on current run score and passes them to `GameScene`.
4. Computes game-over social summaries:
   - next friend ahead from current comparison score
   - friends crossed in `(baselineBest, finalScore]`
5. Emits a pending friend-overtake announcement payload when a score update crosses one or more friend milestones.

`GameScene`:

1. Accepts one or two optional `UpcomingFriendMilestone` entries.
2. Resolves the target car using current score + visible upcoming cars.
3. Renders compact map-pin style avatar markers above target cars (short, slightly right-leaning solid pointer, road-line tint, perspective-aware size scaling, and initials fallback when no avatar).
4. Marker visuals are rendered at a high source size and scaled down at placement time to improve edge and avatar quality.
5. Marker rendering path avoids per-marker repeated color-resolution work and uses lightweight overlap grouping keys to reduce per-frame allocation pressure.
6. Debug builds can enable SpriteKit frame diagnostics (`FPS` and `node count`) from Settings for in-device performance validation.
7. Runtime debug diagnostics are enabled via scene-level `SKView` flags (`showsFPS`/`showsNodeCount`) and SpriteKit’s built-in overlay (no custom sampled in-game stats overlay).
8. Friend-marker rendering is split between `GameScene+FriendMilestones.swift` (placement/progression) and `GameScene+FriendMilestones+Badge.swift` (badge/avatar composition) to keep `GameScene+Grid.swift` focused on grid/road rendering.

`GameOverView`:

1. Optional social section below speed row.
2. Displays next friend ahead (single row with avatar + score).
3. Displays overtaken friends list capped to 3 plus `+N more` (each row with avatar + score).
4. Social score rows expose a combined accessibility element (avatar hidden from accessibility, single row announcement with friend name + score).

## Accessibility

1. In-race marker has VoiceOver label describing upcoming friend score.
2. No essential information relies on animation.
3. Game-over social rows use semantic fonts from `FontPreferenceStore` and remain text-first.
4. At accessibility Dynamic Type sizes, game-over social rows stack avatar above score text for legibility while preserving a single combined accessibility announcement per row.

## Testing Strategy

Unit tests cover:

1. `GameCenterService` unauthenticated snapshot behavior.
2. Friend snapshot normalization (filter, dedupe, sort, baseline retention).
3. `GameViewModel` baseline selection and social summary computation.
4. `GameScene` milestone-to-car mapping logic.
5. Existing score submission/game-over flows continue to work without social data.
