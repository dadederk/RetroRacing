import Foundation
@testable import RetroRacingShared

struct MockLeaderboardConfiguration: LeaderboardConfiguration {
    let cruiseLeaderboardID: String
    let fastLeaderboardID: String
    let rapidLeaderboardID: String

    init(leaderboardID: String) {
        self.cruiseLeaderboardID = leaderboardID
        self.fastLeaderboardID = leaderboardID
        self.rapidLeaderboardID = leaderboardID
    }

    init(cruiseLeaderboardID: String, fastLeaderboardID: String, rapidLeaderboardID: String) {
        self.cruiseLeaderboardID = cruiseLeaderboardID
        self.fastLeaderboardID = fastLeaderboardID
        self.rapidLeaderboardID = rapidLeaderboardID
    }

    func leaderboardID(for difficulty: GameDifficulty) -> String {
        switch difficulty {
        case .cruise:
            return cruiseLeaderboardID
        case .fast:
            return fastLeaderboardID
        case .rapid:
            return rapidLeaderboardID
        @unknown default:
            return rapidLeaderboardID
        }
    }
}
