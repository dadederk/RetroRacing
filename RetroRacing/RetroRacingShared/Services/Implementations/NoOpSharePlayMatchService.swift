//
//  NoOpSharePlayMatchService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Inert `SharePlayMatchService` used on platforms outside the v1 SharePlay scope
/// (macOS, tvOS, watchOS, visionOS), in tests, and in previews. Every call is a no-op and
/// `observeIncomingSessions()` returns immediately instead of awaiting forever, so callers
/// never block waiting on SharePlay activity that will never arrive.
public final class NoOpSharePlayMatchService: SharePlayMatchService, Sendable {
    public init() {}

    public func setStateChangeHandler(_ handler: @escaping @Sendable (SharePlayMatchState) -> Void) async {}

    public func currentRole() async -> SharePlayPlayerRole? { nil }

    public func startHostSession() async {
        AppLog.info(
            AppLog.game,
            "SHAREPLAY_START_HOST_SESSION",
            outcome: .ignored,
            fields: [.reason("noop_service")]
        )
    }

    public func prepareHostActivation() async {}

    public func cancelHostActivation() async {}

    public func observeIncomingSessions() async {}

    public func hostStartRoundIfReady(difficulty: GameDifficulty) async {}

    public func updateLocalScore(_ score: Int, lives: Int) async {}

    public func currentOpponentDisplayName() async -> String? { nil }

    public func reportLocalElimination(finalScore: Int) async {}

    public func retry() async {}

    public func leaveSession() async {}
}
