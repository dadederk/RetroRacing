import Foundation

public protocol LeaderboardService {
    func submitScore(_ score: Int)
    func isAuthenticated() -> Bool
}
