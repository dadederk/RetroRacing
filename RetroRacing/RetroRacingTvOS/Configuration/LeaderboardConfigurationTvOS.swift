import Foundation
import RetroRacingShared

struct LeaderboardConfigurationTvOS: LeaderboardConfiguration {
    func leaderboardID(for difficulty: GameDifficulty) -> String {
        LeaderboardIDCatalog.leaderboardID(platform: .tvOS, difficulty: difficulty)
    }
}
