//
//  SharePlayMatchService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Drives a single 2-player SharePlay competitive match. Implementations own the transport
/// (GroupActivities on iOS/iPad in production, no-op elsewhere) and the underlying
/// `SharePlayMatchStateMachine`, and report state changes back to the caller via
/// `setStateChangeHandler`. Views/view models never talk to GroupActivities directly.
public protocol SharePlayMatchService: AnyObject, Sendable {
    /// Registers a handler invoked whenever the match state changes. The handler itself hops
    /// to the main actor before touching UI-bound state (see `GameViewModel+SharePlay.swift`).
    /// Call once, before starting or observing sessions. Replaces any previously set handler.
    func setStateChangeHandler(_ handler: @escaping @Sendable (SharePlayMatchState) -> Void) async

    /// The local participant's role in the active/most recent session, or `nil` before any
    /// session has started.
    func currentRole() async -> SharePlayPlayerRole?

    /// Starts a new SharePlay activity as host. Only succeeds when the device is already in a
    /// FaceTime call or Messages conversation (`GroupStateObserver.isEligibleForGroupSession`);
    /// callers must check that first and fall back to presenting a system sharing sheet
    /// (`prepareHostActivation()`) otherwise.
    func startHostSession() async

    /// Marks host intent without presenting any system UI. Call immediately before presenting a
    /// `GroupActivitySharingController` sheet (used when the device isn't currently in a
    /// FaceTime call), so the session that sheet starts — once delivered via
    /// `observeIncomingSessions()` — is correctly treated as host rather than guest.
    func prepareHostActivation() async

    /// Clears a pending host activation when the sharing UI is dismissed without starting a
    /// session (Cancel / swipe-to-dismiss).
    func cancelHostActivation() async

    /// Awaits and joins any incoming (system-activated) SharePlay session for this activity.
    /// Intended to run for the lifetime of the app in a single long-lived `.task`.
    func observeIncomingSessions() async

    /// Host-only: call once both participants are ready to begin the synchronized countdown
    /// for a round at the given shared difficulty. No-op for guests.
    func hostStartRoundIfReady(difficulty: GameDifficulty) async

    /// Reports the local player's live score and remaining lives during a round.
    func updateLocalScore(_ score: Int, lives: Int) async

    /// The remote participant's display name when a session is active, or `nil`.
    func currentOpponentDisplayName() async -> String?

    /// Reports that the local player's run ended (collision/game over). Implementations must send
    /// the final `scoreUpdate(score: finalScore, lives: 0)` before the elimination command.
    func reportLocalElimination(finalScore: Int) async

    /// Confirms local intent to play again after a finished round.
    func retry() async

    /// Leaves/ends the current SharePlay session and resets state to `.idle`.
    func leaveSession() async
}
