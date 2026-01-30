//
//  StoreReviewService.swift
//  RetroRacing
//
//  Created by Dani on 30/01/2026.
//

import Foundation

#if canImport(StoreKit)
import StoreKit
#endif

#if canImport(AppStore)
import AppStore
#endif

#if os(iOS)
import UIKit
#endif

final class StoreReviewService: RatingService {
    private let userDefaults: UserDefaults
    private let minimumScoreThreshold = 200
    private let minimumGamesPlayedBeforePrompting = 3
    private let daysBetweenPrompts = 90
    
    private enum Keys {
        static let lastPromptDate = "StoreReview.lastPromptDate"
        static let gamesPlayed = "StoreReview.gamesPlayed"
        static let hasRatedCurrentVersion = "StoreReview.hasRatedVersion_\(appVersion)"
    }
    
    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func requestRating() {
        #if os(iOS)
        // iOS 18+ uses AppStore.requestReview
        Task {
            if let windowScene = findActiveWindowScene() {
                await AppStore.requestReview(in: windowScene)
                recordPrompt()
            }
        }
        #elseif os(macOS)
        SKStoreReviewController.requestReview()
        recordPrompt()
        #elseif os(tvOS)
        // App Store reviews are not supported on tvOS
        #endif
    }
    
    func checkAndRequestRating(score: Int) {
        // Implementation can be added later for automatic prompting
        // For now, relying on manual requestRating() calls
    }
    
    // MARK: - Private Helpers
    
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
    
    private func meetsScoreThreshold(score: Int, isNewBestScore: Bool) -> Bool {
        isNewBestScore && score >= minimumScoreThreshold
    }
    
    private func recordPrompt() {
        userDefaults.set(Date(), forKey: Keys.lastPromptDate)
        userDefaults.set(true, forKey: Keys.hasRatedCurrentVersion)
    }
    
    #if os(iOS)
    private func findActiveWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
    #endif
}
