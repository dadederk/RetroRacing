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
            AppLog.info(
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_SENDER_ACTIVATE",
                outcome: .skipped,
                fields: [
                    .reason("wc_session_not_supported")
                ]
            )
            return
        }
        guard session.activationState != .activated else { return }
        session.activate()
    }

    func relayBestScore(_ score: Int, difficulty: GameDifficulty) {
        guard let session else {
            AppLog.info(
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_SCORE_QUEUE",
                outcome: .skipped,
                fields: [
                    .reason("wc_session_not_supported"),
                    .int("score", score),
                    .string("speed", difficulty.rawValue)
                ]
            )
            return
        }

        if session.activationState != .activated {
            session.activate()
        }

        let payload = WatchBestScoreRelayPayload(score: score, difficulty: difficulty)
        session.transferUserInfo(payload.userInfo)
        AppLog.info(
            AppLog.leaderboard + AppLog.lifecycle,
            "WATCH_RELAY_SCORE_QUEUE",
            outcome: .requested,
            fields: [
                .int("score", score),
                .string("speed", difficulty.rawValue)
            ]
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
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_SENDER_ACTIVATE",
                outcome: .failed,
                fields: [
                    .reason("activation_failed")
                ] + AppLog.Field.error(error)
            )
            return
        }

        AppLog.info(
            AppLog.leaderboard + AppLog.lifecycle,
            "WATCH_RELAY_SENDER_ACTIVATE",
            outcome: .succeeded,
            fields: [
                .int("activationState", activationState.rawValue)
            ]
        )
    }
}
#endif
