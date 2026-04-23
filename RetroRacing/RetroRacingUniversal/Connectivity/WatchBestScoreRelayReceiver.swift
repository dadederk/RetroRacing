//
//  WatchBestScoreRelayReceiver.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation
import RetroRacingShared

#if os(iOS) && canImport(WatchConnectivity)
import WatchConnectivity

final class WatchBestScoreRelayReceiver: NSObject {
    private let ingestionService: WatchRelayedBestScoreIngestionService
    private let session: WCSession?

    init(ingestionService: WatchRelayedBestScoreIngestionService) {
        self.ingestionService = ingestionService
        if WCSession.isSupported() {
            session = WCSession.default
        } else {
            session = nil
        }
        super.init()

        session?.delegate = self
    }

    func activate() {
        guard let session else {
            AppLog.info(
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_RECEIVER_ACTIVATE",
                outcome: .skipped,
                fields: [
                    .reason("wc_session_not_supported")
                ]
            )
            return
        }
        session.activate()
    }
}

extension WatchBestScoreRelayReceiver: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            AppLog.error(
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_RECEIVER_ACTIVATE",
                outcome: .failed,
                fields: [
                    .reason("activation_failed")
                ] + AppLog.Field.error(error)
            )
            return
        }

        AppLog.info(
            AppLog.leaderboard + AppLog.lifecycle,
            "WATCH_RELAY_RECEIVER_ACTIVATE",
            outcome: .succeeded,
            fields: [
                .int("activationState", activationState.rawValue)
            ]
        )
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let payload = WatchBestScoreRelayPayload.from(userInfo: userInfo) else {
            AppLog.error(
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_PAYLOAD_RECEIVE",
                outcome: .failed,
                fields: [
                    .reason("invalid_payload"),
                    .int("keyCount", userInfo.count)
                ]
            )
            return
        }

        guard let difficulty = payload.difficulty else {
            AppLog.error(
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_PAYLOAD_RECEIVE",
                outcome: .failed,
                fields: [
                    .reason("invalid_difficulty"),
                    .string("difficulty", payload.difficultyRawValue)
                ]
            )
            return
        }

        AppLog.debug(
            AppLog.leaderboard + AppLog.lifecycle,
            "WATCH_RELAY_PAYLOAD_RECEIVE",
            outcome: .succeeded,
            fields: [
                .int("score", payload.score),
                .string("difficulty", difficulty.rawValue)
            ]
        )

        _ = ingestionService.ingest(score: payload.score, difficulty: difficulty)
        Task {
            await ingestionService.flushPendingIfPossible(trigger: .relayReceived)
        }
    }
}

#else
final class WatchBestScoreRelayReceiver {
    init(ingestionService: WatchRelayedBestScoreIngestionService) {}

    func activate() {}
}
#endif
