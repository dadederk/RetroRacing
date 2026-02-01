import Foundation

public final class StoreReviewService: RatingService {
    private let userDefaults: UserDefaults
    private let ratingProvider: RatingServiceProvider
    private let minimumScoreThreshold = 200
    private let minimumGamesPlayedBeforePrompting = 3
    private let daysBetweenPrompts = 90

    private enum Keys {
        static let lastPromptDate = "StoreReview.lastPromptDate"
        static let gamesPlayed = "StoreReview.gamesPlayed"
        static var hasRatedCurrentVersion: String { "StoreReview.hasRatedVersion_\(appVersion)" }
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    public init(userDefaults: UserDefaults = .standard, ratingProvider: RatingServiceProvider) {
        self.userDefaults = userDefaults
        self.ratingProvider = ratingProvider
    }

    public func requestRating() {
        ratingProvider.presentRatingRequest()
        recordPrompt()
    }

    public func checkAndRequestRating(score: Int) {
        guard shouldPromptForRating(score: score) else { return }
        requestRating()
    }

    /// Call when a game session ends to update games-played count.
    func recordGamePlayed() {
        let count = userDefaults.integer(forKey: Keys.gamesPlayed) + 1
        userDefaults.set(count, forKey: Keys.gamesPlayed)
    }

    // MARK: - Private Helpers

    private func shouldPromptForRating(score: Int) -> Bool {
        guard !hasRatedCurrentVersion() else { return false }
        guard hasEnoughGamesPlayed() else { return false }
        guard hasEnoughTimePassed() else { return false }
        return score >= minimumScoreThreshold
    }

    private func hasRatedCurrentVersion() -> Bool {
        userDefaults.bool(forKey: Keys.hasRatedCurrentVersion)
    }

    private func hasEnoughGamesPlayed() -> Bool {
        userDefaults.integer(forKey: Keys.gamesPlayed) >= minimumGamesPlayedBeforePrompting
    }

    private func hasEnoughTimePassed() -> Bool {
        guard let lastPromptDate = userDefaults.object(forKey: Keys.lastPromptDate) as? Date else {
            return true
        }

        let daysSinceLastPrompt = Calendar.current.dateComponents(
            [.day],
            from: lastPromptDate,
            to: Date()
        ).day ?? 0

        return daysSinceLastPrompt >= daysBetweenPrompts
    }

    private func recordPrompt() {
        userDefaults.set(Date(), forKey: Keys.lastPromptDate)
        userDefaults.set(true, forKey: Keys.hasRatedCurrentVersion)
    }
}
