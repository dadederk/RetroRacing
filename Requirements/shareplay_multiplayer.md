# SharePlay Competitive Mode

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** 2-player SharePlay friend races on iOS/iPad/macOS with host-authoritative round settings, deterministic traffic, local simulation, mirrored score/lives, retry, leave, and free-play behavior.
- **Must not break:** Shared state machine stays pure and `GroupActivities`-free; platform gating stays in the app adapter/composition layer; SharePlay matches never record daily plays; each player submits only their own score through existing leaderboard paths.
- **Key files:** `RetroRacingShared/SharePlay/`, `SharePlayMatchService`, `GroupActivitiesSharePlayMatchService`, `GameViewModel+SharePlay`, `SharePlayOverlayView`, `SharePlayResultView`.

## Scope

- Shipping platforms: iOS, iPad, and macOS through `RetroRacingUniversal`.
- tvOS, watchOS, and visionOS use `NoOpSharePlayMatchService` and do not expose the entry point.
- v1 supports exactly two active participants. More than two must fail safely.
- Plain-English architecture and flow diagrams live in [TechDocs/play-with-friends-shareplay.md](../TechDocs/play-with-friends-shareplay.md).

## Match Lifecycle

- Entry starts from **Play with Friends** or from a system-delivered incoming SharePlay session.
- Host activation is idempotent; repeated taps while activation/session setup is pending are ignored.
- The app enters gameplay only after a delivered `GroupSession` reaches `.joined`.
- Provisional sessions invalidated before `.joined` are discarded without publishing a visible abort.
- Host starts a synchronized countdown only after:
  - exactly two active participants are present
  - the remote peer’s idempotent `.sessionReady` command has been received
- The round progresses through waiting, countdown, in-round, waiting-after-local-loss, finished, retry-waiting, retry-timed-out, or aborted states.
- Leave/Done and in-game menu exit must route through the same finish path: notify the peer, leave the session, stop gameplay/audio, reset game state, and return to menu.

## Gameplay Contract

- The host shares `GameDifficulty` and `trafficSeed` in `SharePlayRoundSettings`.
- The guest temporarily adopts host difficulty and restores their own selected difficulty on finish, timeout, or abort.
- Traffic is deterministic by `(trafficSeed, hazardRowIndex)`:
  - hazardous rows match across peers
  - all-car rows are repaired with a stable empty column
  - local empty safety rows do not consume the shared hazard-row index
- Gameplay is pause-locked while waiting, during countdown, after local loss, during retry waiting/timeout, and after abort.
- The SharePlay countdown uses its own countdown/go cues and starts gameplay without the normal solo start cue.
- Score and remaining lives mirror live during the round.
- On final collision, the local device sends `scoreUpdate(score, lives: 0)` before elimination so the remote HUD reaches zero lives.
- Solo game-over UI is suppressed while SharePlay is active; terminal states use `SharePlayResultView`.

## Service and Adapter Boundaries

- `SharePlayMatchStateMachine` owns pure synchronous transitions and retry timeout semantics.
- `SharePlayMatchService` is the only protocol views/view models use; shared UI must not import `GroupActivities`.
- `GroupActivitiesSharePlayMatchService` and related adapter types own GroupActivities sessions, messenger transport, participant-count policy, activation handoff, timers, and structured SharePlay logging.
- The composition root injects a long-lived service and observes incoming sessions for the app lifetime.
- UI state propagation uses an atomic `SharePlayUIState` snapshot so state, role, and display name do not drift.

## Free-Play and Settings

- SharePlay matches are always free and never call `PlayLimitService.recordGamePlayed`; see [monetization.md](monetization.md#shareplay-exception).
- The **Play with Friends** entry point never routes through the solo paywall gate.
- Settings speed editing is disabled while a SharePlay match is active, including the macOS global settings sheet.

## Result, Retry, and Abort

- Finished results include both final scores, difficulty, and local won/lost/tie outcome.
- Each player taps **Play Again** independently; both ready states reset the match to waiting for a fresh round.
- Retry timeout is terminal after 90 seconds. Result UI must offer Leave only.
- If one timer fires, the service sends `.sessionAborted(reason: .retryTimedOut)` so the peer converges even if its timer is delayed.
- `.disconnected` is reserved for genuine transport/participant loss.
- `.sessionEnded` comes from the remote leave/finish path and should use softer copy.
- Each player still submits only their own score via `LeaderboardService.submitScore`; no leaderboard API changes.

## Localization and Accessibility

- SharePlay copy uses friend wording rather than opponent wording and avoids em dashes.
- HUD rows are concise: `You: <score>` and `<friend>: <score>` or `Friend: <score>`.
- Overlay and result assets come from the first-party SharePlay artwork set.
- VoiceOver countdown announcements are not posted for each second; generated countdown cues provide the audio timing.

## Testing

- Unit tests cover state-machine transitions, retry timeout, two-peer convergence, guest speed restore, deterministic traffic, activation handoff, provisional-session admission, participant-count policy, final-collision ordering, pause locks, and free-play record skipping.
- Manual two-device QA remains required for real GroupActivities transport: invite/cancel/retry, synchronized countdown, score/lives mirroring, disconnect, menu exit, third participant fail-safe, free-play count preservation, and the macOS host/guest matrix.

## Related

- [monetization.md](monetization.md) — free-play exception.
- [launch_flow.md](launch_flow.md) — menu entry point.
- [accessibility.md](accessibility.md) — overlay accessibility behavior.
- [testing.md](testing.md) — validation strategy.
- [TechDocs/play-with-friends-shareplay.md](../TechDocs/play-with-friends-shareplay.md) — architecture explainer.
