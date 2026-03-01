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
            AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 iPhone watch relay receiver unavailable: WCSession not supported")
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
                AppLog.game + AppLog.leaderboard,
                "🏆 iPhone watch relay receiver activation failed: \(error.localizedDescription)"
            )
            return
        }

        AppLog.info(
            AppLog.game + AppLog.leaderboard,
            "🏆 iPhone watch relay receiver activated (state: \(activationState.rawValue))"
        )
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let payload = WatchBestScoreRelayPayload.from(userInfo: userInfo) else {
            AppLog.error(
                AppLog.game + AppLog.leaderboard,
                "🏆 iPhone watch relay receiver dropped invalid payload: \(userInfo)"
            )
            return
        }

        guard let difficulty = payload.difficulty else {
            AppLog.error(
                AppLog.game + AppLog.leaderboard,
                "🏆 iPhone watch relay receiver dropped payload with invalid difficulty: \(payload.difficultyRawValue)"
            )
            return
        }

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
