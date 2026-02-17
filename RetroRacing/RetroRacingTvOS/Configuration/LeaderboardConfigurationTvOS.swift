import Foundation
import RetroRacingShared

struct LeaderboardConfigurationTvOS: LeaderboardConfiguration {
    func leaderboardID(for difficulty: GameDifficulty) -> String {
        switch difficulty {
        case .cruise:
            return "besttvos001cruise"
        case .fast:
            return "besttvos001fast"
        case .rapid:
            return "besttvos001"
        @unknown default:
            return "besttvos001"
        }
    }
}
