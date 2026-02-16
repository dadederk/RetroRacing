//
//  StoreReviewService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Rating prompt coordinator that throttles StoreKit requests based on gameplay activity.
public final class StoreReviewService: RatingService {
    private let userDefaults: UserDefaults
    private let ratingProvider: RatingServiceProvider
    private let minimumBestScoreImprovementsBeforePrompting = 3
    private let daysBetweenPrompts = 90

    private enum Keys {
        static let lastPromptDate = "StoreReview.lastPromptDate"
        static var bestScoreImprovementsCurrentVersion: String { "StoreReview.bestScoreImprovements_\(appVersion)" }
        static var hasRatedCurrentVersion: String { "StoreReview.hasRatedVersion_\(appVersion)" }
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    public init(userDefaults: UserDefaults, ratingProvider: RatingServiceProvider) {
        self.userDefaults = userDefaults
        self.ratingProvider = ratingProvider
    }

    public func requestRating() {
        ratingProvider.presentRatingRequest()
        recordPrompt()
    }

    public func recordBestScoreImprovementAndRequestIfEligible() {
        let improvementCount = incrementBestScoreImprovementCount()
        guard shouldPromptForRating(bestScoreImprovementCount: improvementCount) else { return }
        requestRating()
    }

    // MARK: - Private Helpers

    private func shouldPromptForRating(bestScoreImprovementCount: Int) -> Bool {
        guard !hasRatedCurrentVersion() else { return false }
        guard hasEnoughBestScoreImprovements(bestScoreImprovementCount) else { return false }
        guard hasEnoughTimePassed() else { return false }
        return true
    }

    private func hasRatedCurrentVersion() -> Bool {
        userDefaults.bool(forKey: Keys.hasRatedCurrentVersion)
    }

    private func hasEnoughBestScoreImprovements(_ count: Int) -> Bool {
        count >= minimumBestScoreImprovementsBeforePrompting
    }

    private func incrementBestScoreImprovementCount() -> Int {
        let count = userDefaults.integer(forKey: Keys.bestScoreImprovementsCurrentVersion) + 1
        userDefaults.set(count, forKey: Keys.bestScoreImprovementsCurrentVersion)
        return count
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
