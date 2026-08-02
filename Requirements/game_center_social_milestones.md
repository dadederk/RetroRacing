# Game Center Social Milestones

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Friend-aware in-race markers and game-over social recap on Universal and tvOS.
- **Must not break:** Uses selected difficulty leaderboard; shows at most two in-race markers; hides gracefully when data is unavailable; watchOS remains out of scope for v1.
- **Key files:** friend leaderboard models/services, `GameViewModel`, `GameScene+FriendMilestones`, `GameOverView`.

## Behavior Contract

- Social milestones use the same platform/speed leaderboard as score submission.
- Friend data uses all-time friends scope.
- If authentication, fetch, avatar hydration, or friend data is unavailable, social UI is hidden.
- In-race markers compare against current run score so milestones can appear every run.
- Game-over comparisons use remote Game Center best at run start when available, otherwise local best.

## In-Race Markers

- Show up to two nearest upcoming friend scores.
- Resolve marker placement to visible upcoming cars.
- Render compact avatar/initial markers above target cars with perspective-aware sizing.
- iPadOS and macOS may scale badges larger than iPhone/tvOS.
- Marker accessibility labels include friend name and target score.

## Game-Over Recap

- Optional social section appears below the speed row.
- Shows next friend ahead when applicable.
- Shows overtaken friends crossed in `(baselineBest, finalScore]`, capped to three plus `+N more`.
- Rows combine avatar, friend name, and score into one accessibility element.
- At accessibility Dynamic Type sizes, rows may stack for legibility.

## Data Model and Service

- `LeaderboardService.fetchFriendLeaderboardSnapshot(for:)` returns an optional snapshot.
- Snapshot loading filters invalid rows, dedupes by player ID, sorts by ascending score, retains remote local-player best, and caches bounded avatar PNG data in memory.

## Testing

- Unit tests cover unauthenticated behavior, snapshot normalization, baseline selection, summary computation, milestone-to-car mapping, badge sizing, accessibility labels, and unaffected score submission when no social data exists.
