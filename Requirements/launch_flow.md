# Launch and Menu Flow

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Game-base plus menu-overlay launch flow, session identity, Play/Finish behavior, overlay pause, and Play with Friends entry.
- **Must not break:** SpriteKit scene starts only after Play; each Play creates a fresh `sessionID`; Finish resets to pre-game menu state; overlays pause without overriding explicit user pause.
- **Key files:** Universal/tvOS app entries, `GameView`, `MenuView`, `GameViewModel`.

## Session Model

- Universal and tvOS root views are `GameView` with a menu overlay above it.
- Initial launch sets `shouldStartGame = false` and presents `MenuView`.
- A `sessionID` identifies a continuous gameplay session.
- Tapping **Play** always creates a new `sessionID`, sets `shouldStartGame = true`, and dismisses the menu.
- `GameViewModel.setupSceneIfNeeded` must not create a `GameScene` until `shouldStartGame` is true.
- Game-over Restart restarts the current gameplay flow after play-limit checks.
- Game-over Finish dismisses the sheet, sets `shouldStartGame = false`, creates a fresh `sessionID`, and presents the menu.

## Overlay and Pause

- iOS/iPadOS/tvOS use `.fullScreenCover` for the menu.
- macOS uses an in-window overlay, not a menu sheet.
- Opening menu/settings while gameplay is active pauses gameplay immediately.
- Overlay-driven pause is separate from user-driven pause.
- Dismissing an overlay resumes only when the user did not explicitly pause.
- Deferred audio/start callbacks must not clear an active overlay pause lock.
- Toolbar controls are disabled when no game is active or an overlay is visible.

## Platform Notes

- iOS/iPadOS: menu button during gameplay may reopen the overlay and starts a new run when Play is tapped again.
- macOS: minimum window size is 820 x 620; `Cmd+,` opens root-owned Settings; underlying gameplay is hidden from accessibility while the modal overlay is visible.
- tvOS: movement uses `onMoveCommand`; Play/Pause remote button toggles pause.
- watchOS and visionOS may keep different navigation patterns unless explicitly migrated.

## Play with Friends

- The button is shown only when the composition root supplies `onPlayWithFriendsRequest`.
- It is available on iOS/iPad/macOS and hidden on tvOS/watchOS/visionOS.
- It never routes through solo play-limit or paywall checks; SharePlay races are free.
- Host activation and incoming sessions enter gameplay only after a delivered SharePlay session reaches `.joined`.
- Provisional sessions that invalidate before join remain invisible and must not show Connection Lost.
- SharePlay details live in [shareplay_multiplayer.md](shareplay_multiplayer.md).

## Accessibility

- Full-screen menu covers are `.interactiveDismissDisabled(true)` so Play is the explicit start path.
- When the macOS menu overlay is visible, it is modal and the underlying game is hidden from the accessibility tree.
- VoiceOver users should land back on a clean menu state after Finish.

## Testing

- Verify initial launch does not start gameplay before Play.
- Verify Play creates a new session from initial menu and in-game menu.
- Verify Finish resets session state and returns to the menu.
- Verify overlay pause/resume respects explicit user pause.
- Verify SharePlay entry starts without paywall and only after admitted joined session.
