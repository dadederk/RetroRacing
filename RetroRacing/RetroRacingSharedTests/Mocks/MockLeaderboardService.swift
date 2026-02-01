import Foundation
@testable import RetroRacingShared

final class MockLeaderboardService: LeaderboardService {
    var submittedScores: [Int] = []
    var authenticated = true

    func submitScore(_ score: Int) {
        submittedScores.append(score)
    }

    func isAuthenticated() -> Bool {
        authenticated
    }
}
