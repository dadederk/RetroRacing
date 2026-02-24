import Foundation
@testable import RetroRacingShared

final class MockLeaderboardService: LeaderboardService {
    var submittedScores: [Int] = []
    var submittedDifficulties: [GameDifficulty] = []
    var authenticated = true
    var remoteBestScoresByDifficulty: [GameDifficulty: Int] = [:]

    func submitScore(_ score: Int, difficulty: GameDifficulty) {
        submittedScores.append(score)
        submittedDifficulties.append(difficulty)
    }

    func isAuthenticated() -> Bool {
        authenticated
    }

    func fetchLocalPlayerBestScore(for difficulty: GameDifficulty) async -> Int? {
        remoteBestScoresByDifficulty[difficulty]
    }
}

final class MockRandomSource: RandomSource {
    private var values: [Int]

    init(values: [Int] = []) {
        self.values = values
    }

    func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        guard values.isEmpty == false else { return 0 }
        let value = values.removeFirst()
        return value % upperBound
    }
}

final class MockHapticFeedbackController: HapticFeedbackController {
    private(set) var crashes = 0
    private(set) var gridUpdates = 0
    private(set) var moves = 0
    private(set) var successes = 0
    private(set) var warnings = 0

    func triggerCrashHaptic() { crashes += 1 }
    func triggerGridUpdateHaptic() { gridUpdates += 1 }
    func triggerMoveHaptic() { moves += 1 }
    func triggerSuccessHaptic() { successes += 1 }
    func triggerWarningHaptic() { warnings += 1 }
}
