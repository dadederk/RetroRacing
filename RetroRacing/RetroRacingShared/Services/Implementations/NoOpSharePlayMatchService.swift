//
//  NoOpSharePlayMatchService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Inert `SharePlayMatchService` used on platforms without Group Activities,
/// in tests, and in previews. Every call is a no-op and
/// `observeIncomingSessions()` returns immediately instead of awaiting forever, so callers
/// never block waiting on SharePlay activity that will never arrive.
public final class NoOpSharePlayMatchService: SharePlayMatchService, Sendable {
    public init() {}

    public func setStateChangeHandler(
        _ handler: @escaping @Sendable (SharePlayUIState) async -> Void
    ) async {}

    public func prepareHostActivation() async -> Bool { false }

    public func activatePendingHostSession(reason: SharePlayHostActivationReason) async -> Bool { false }

    public func cancelHostActivation(reason: SharePlayHostActivationReason) async {}

    public func observeIncomingSessions() async {}

    public func hostStartRoundIfReady(difficulty: GameDifficulty) async {}

    public func updateLocalScore(_ score: Int, lives: Int) async {}

    public func reportLocalElimination(finalScore: Int) async {}

    public func retry() async {}

    public func leaveSession() async {}
}
