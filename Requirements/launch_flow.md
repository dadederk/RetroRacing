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

- iOS/iPadOS use `.fullScreenCover` for the menu. tvOS keeps `GameView` mounted beneath an app-owned opaque menu overlay so remote Back cannot dismiss the menu into an unstarted game.
- macOS uses an in-window overlay, not a menu sheet.
- Opening menu/settings while gameplay is active pauses gameplay immediately.
- On tvOS, Menu/Back first opens a finish confirmation and applies the same overlay pause lock.
- Choosing Keep Playing dismisses that confirmation and resumes only when the user had not explicitly paused.
- Choosing Finish applies the normal finish transition: stop the current race, create a fresh session identity, and return to the pre-game menu.
- Overlay-driven pause is separate from user-driven pause.
- Dismissing an overlay resumes only when the user did not explicitly pause.
- Deferred audio/start callbacks must not clear an active overlay pause lock.
- Toolbar controls are disabled when no game is active or an overlay is visible.

## Platform Notes

- iOS/iPadOS: menu button during gameplay may reopen the overlay and starts a new run when Play is tapped again.
- iOS/iPadOS compact landscape: the game square may extend into the top safe area to maximize play space without becoming smaller than the safe-area-constrained square; toolbar-adjacent chrome reapplies the measured top safe-area inset and screenshot capture keeps deterministic sizing.
- macOS: minimum window size is 820 x 620; `Cmd+,` opens root-owned Settings; underlying gameplay is hidden from accessibility while the modal overlay is visible.
- tvOS: movement uses `onMoveCommand`; Play/Pause toggles pause; Menu/Back confirms before finishing the race and pops one menu-owned Tutorial or Settings destination at a time. Menu/Back is inert at the menu root.
- watchOS keeps its platform navigation. visionOS uses the shared universal-style menu and one shared-session coordinator across unique Classic/Tabletop windows. Classic gameplay keeps an X in the top-left and Pause/Resume in the top-right; Settings is available from the menu only. The X presents the same Keep Playing/Finish alert contract as tvOS. App inactivity pauses the engine and resets scheduler wall-time before resuming. See [visionos_gameplay.md](visionos_gameplay.md).

## Play with Friends

- The button is shown only when the composition root supplies `onPlayWithFriendsRequest`.
- It starts a synchronized race on iOS/iPad/macOS/tvOS and visionOS Classic, and is hidden on watchOS. tvOS explains the FaceTime-group prerequisite when direct activation is not eligible. visionOS automatically leaves Tabletop for Classic before applying an incoming match.
- It never routes through solo play-limit or paywall checks; SharePlay races are free.
- Host activation and incoming sessions enter gameplay only after a delivered SharePlay session reaches `.joined`.
- Provisional sessions that invalidate before join remain invisible and must not show Connection Lost.
- SharePlay details live in [shareplay_multiplayer.md](shareplay_multiplayer.md).

## Accessibility

- iOS/iPadOS full-screen menu covers are `.interactiveDismissDisabled(true)` so Play is the explicit start path. The tvOS app-owned overlay has no system dismissal path.
- When the macOS menu overlay is visible, it is modal and the underlying game is hidden from the accessibility tree.
- VoiceOver users should land back on a clean menu state after Finish.

## Testing

- Verify initial launch does not start gameplay before Play.
- Verify Play creates a new session from initial menu and in-game menu.
- Verify Finish resets session state and returns to the menu.
- Verify overlay pause/resume respects explicit user pause.
- Verify SharePlay entry starts without paywall and only after admitted joined session.
- Verify top-safe-area expansion is limited to compact landscape outside screenshot capture, preserves the prior square size in width-limited layouts, and keeps side-rail chrome below the measured top inset.
