# SharePlay Competitive Mode Plan (iOS+iPad v1)

## Summary

Implement SharePlay competitive multiplayer for 2 players on iOS and iPad first, with synchronized starts, live post-loss waiting, synced final result, and dual-retry rematch flow.

## Locked Decisions

- Scope: iOS+iPad v1.
- Players: exactly 2.
- Entry UX: menu button plus incoming SharePlay join handling.
- Start sync: host-authoritative start timestamp plus a 3-second countdown.
- Sync model: local gameplay simulation on each device, with shared session events and score updates.
- Difficulty: host-selected speed for shared round conditions.
- Winner: higher score wins, ties allowed.
- First loser: sees lose/waiting screen with spinner and live opponent score.
- Final result: both players see the same win/lose/tie result with both scores.
- Retry: both players must tap Retry.
- Retry timeout: 30 seconds, then timeout UI with clear recovery actions.
- Disconnect: abort match/session for both.
- Leaderboards: each player submits their own final score.
- Guest speed restore: non-host temporarily uses host speed during SharePlay, then restores original local speed when SharePlay session ends.

## Architecture

- Add `SharePlayMatchService` protocol in shared services (DI-only, no default instantiation).
- Add shared state machine and models:
  - `SharePlayMatchState`
  - `SharePlayMatchCommand`
  - `SharePlayRoundResult`
- Add iOS/iPad GroupActivities adapter:
  - `RetroRacingGroupActivity`
  - `GroupSession` lifecycle manager
  - `GroupSessionMessenger` transport
- Use host-authoritative session events:
  - `sessionReady`
  - `roundStart(startAt, difficulty)`
  - `scoreUpdate`
  - `playerEliminated`
  - `roundResult`
  - `retryReady`
  - `sessionFinished` / `sessionAborted`

## UI and Flow Integration

- Add a "Play with Friends" action in `MenuView`.
- Support incoming SharePlay session join from system activation.
- Extend game UI with SharePlay states:
  - waiting for friend
  - synchronized countdown
  - in-round
  - local-lost waiting
  - final result
  - retry waiting and timeout
  - aborted
- Keep solo mode behavior unchanged when SharePlay is inactive.
- Lock difficulty editing while SharePlay is active.
- Apply guest speed restore on terminal SharePlay states.

## Implementation Touchpoints

- `RetroRacing/RetroRacingUniversal/App/RetroRacingApp.swift`
- `RetroRacing/RetroRacingShared/Views/GameView.swift`
- `RetroRacing/RetroRacingShared/Views/GameViewModel.swift`
- `RetroRacing/RetroRacingShared/Views/GameOverView.swift`
- `RetroRacing/RetroRacingShared/Services/Protocols/` (new protocol and models)
- `RetroRacing/RetroRacingShared/Services/Implementations/` (new SharePlay adapter)
- Universal target capabilities and entitlements (Group Activities)

## Testing

- Unit tests for SharePlay state-machine transitions.
- Unit tests for winner/tie computation and mirrored final-result payload.
- Unit tests for retry handshake plus 30-second timeout.
- Unit tests for guest speed capture and restore on normal finish and abort.
- Integration tests with mocked transport proving both peers converge to the same terminal state.
- Manual 2-device SharePlay validation for full lifecycle, including disconnect behavior.

## Requirements Docs Updates

- Add `Requirements/shareplay_multiplayer.md`.
- Update:
  - `Requirements/launch_flow.md`
  - `Requirements/testing.md`
  - `Requirements/accessibility.md`
- Add localization keys for SharePlay UI states in EN/ES/CA.

## Follow-Ups (Post-v1)

- Expand support to macOS and tvOS after iOS+iPad stabilization.
- Optional best-of-3 session mode.
- Optional richer spectator feedback after local elimination.
