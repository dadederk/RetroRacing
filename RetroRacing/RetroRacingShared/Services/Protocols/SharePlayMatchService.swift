//
//  SharePlayMatchService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Drives a single 2-player SharePlay competitive match. Implementations own the transport
/// (GroupActivities on iOS/iPad/macOS in production, no-op elsewhere) and the underlying
/// `SharePlayMatchStateMachine`, and report state changes back to the caller via
/// `setStateChangeHandler`. Views/view models never talk to GroupActivities directly.
public protocol SharePlayMatchService: AnyObject, Sendable {
    /// Registers a handler invoked whenever the match UI state changes. The composition root hops
    /// to the main actor before touching UI-bound state. Call once, before starting or observing
    /// sessions. Replaces any previously set handler.
    func setStateChangeHandler(
        _ handler: @escaping @Sendable (SharePlayUIState) async -> Void
    ) async

    /// Marks activation intent without presenting system UI or activating the activity. Call
    /// immediately before either host-start route so duplicate activation requests can be ignored
    /// until the system delivers or cancels the resulting session.
    /// Returns `true` only when the caller should continue the host-start request.
    func prepareHostActivation() async -> Bool

    /// Activates the already-prepared host request in an eligible FaceTime or Messages
    /// conversation. Returns `true` when activation started or a session was delivered while the
    /// activation request was in flight.
    func activatePendingHostSession(reason: SharePlayHostActivationReason) async -> Bool

    /// Clears a pending host activation request without affecting any real session that may later
    /// arrive through `observeIncomingSessions()`. The reason is logged by production adapters so
    /// two-device SharePlay captures can distinguish user cancellation from an invite handoff.
    func cancelHostActivation(reason: SharePlayHostActivationReason) async

    /// Awaits and joins any incoming (system-activated) SharePlay session for this activity.
    /// Intended to run for the lifetime of the app in a single long-lived `.task`.
    func observeIncomingSessions() async

    /// Host-only: call once both participants are ready to begin the synchronized countdown
    /// for a round at the given shared difficulty. No-op for guests.
    func hostStartRoundIfReady(difficulty: GameDifficulty) async

    /// Reports the local player's live score and remaining lives during a round.
    func updateLocalScore(_ score: Int, lives: Int) async

    /// Reports that the local player's run ended (collision/game over). Implementations must send
    /// the final `scoreUpdate(score: finalScore, lives: 0)` before the elimination command.
    func reportLocalElimination(finalScore: Int) async

    /// Confirms local intent to play again after a finished round.
    func retry() async

    /// Leaves/ends the current SharePlay session and resets state to `.idle`.
    func leaveSession() async
}
