//
//  WatchConnectivityBestScoreRelaySender.swift
//  RetroRacingWatchOS
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation
import RetroRacingShared
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

#if canImport(WatchConnectivity)
final class WatchConnectivityBestScoreRelaySender: NSObject, WatchBestScoreRelaySender {
    private let session: WCSession?

    override init() {
        if WCSession.isSupported() {
            session = WCSession.default
        } else {
            session = nil
        }
        super.init()

        session?.delegate = self
    }

    func activateIfPossible() {
        guard let session else {
            AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS score relay unavailable: WCSession not supported")
            return
        }
        guard session.activationState != .activated else { return }
        session.activate()
    }

    func relayBestScore(_ score: Int, difficulty: GameDifficulty) {
        guard let session else {
            AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS score relay skipped: WCSession unsupported")
            return
        }

        if session.activationState != .activated {
            session.activate()
        }

        let payload = WatchBestScoreRelayPayload(score: score, difficulty: difficulty)
        session.transferUserInfo(payload.userInfo)
        AppLog.info(
            AppLog.game + AppLog.leaderboard,
            "🏆 watchOS queued relayed best \(score) for speed \(difficulty.rawValue) via WatchConnectivity"
        )
    }
}

extension WatchConnectivityBestScoreRelaySender: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            AppLog.error(
                AppLog.game + AppLog.leaderboard,
                "🏆 watchOS score relay session activation failed: \(error.localizedDescription)"
            )
            return
        }

        AppLog.info(
            AppLog.game + AppLog.leaderboard,
            "🏆 watchOS score relay session activated (state: \(activationState.rawValue))"
        )
    }
}
#endif
