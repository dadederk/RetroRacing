//
//  StoreReviewServiceTests.swift
//  RetroRacingSharedTests
//

import XCTest
@testable import RetroRacingShared

private final class MockRatingServiceProvider: RatingServiceProvider {
    var presentRatingRequestCallCount = 0
    func presentRatingRequest() {
        presentRatingRequestCallCount += 1
    }
}

final class StoreReviewServiceTests: XCTestCase {
    func testGivenManualRequestWhenRequestRatingThenProviderCalledAndPromptDateRecorded() {
        // Given
        let suiteName = "StoreReviewServiceTests.manualRequest"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let provider = MockRatingServiceProvider()
        let service = StoreReviewService(userDefaults: defaults, ratingProvider: provider)

        // When
        service.requestRating()

        // Then
        XCTAssertEqual(provider.presentRatingRequestCallCount, 1)
        XCTAssertNotNil(defaults.object(forKey: "StoreReview.lastPromptDate"))
    }

    func testGivenTwoBestScoreImprovementsWhenRecordingThenRatingIsNotRequested() {
        // Given
        let suiteName = "StoreReviewServiceTests.twoImprovements"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let provider = MockRatingServiceProvider()
        let service = StoreReviewService(userDefaults: defaults, ratingProvider: provider)

        // When
        service.recordBestScoreImprovementAndRequestIfEligible()
        service.recordBestScoreImprovementAndRequestIfEligible()

        // Then
        XCTAssertEqual(provider.presentRatingRequestCallCount, 0)
    }

    func testGivenThreeBestScoreImprovementsWhenRecordingThenRatingIsRequestedOnce() {
        // Given
        let suiteName = "StoreReviewServiceTests.threeImprovements"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let provider = MockRatingServiceProvider()
        let service = StoreReviewService(userDefaults: defaults, ratingProvider: provider)

        // When
        service.recordBestScoreImprovementAndRequestIfEligible()
        service.recordBestScoreImprovementAndRequestIfEligible()
        service.recordBestScoreImprovementAndRequestIfEligible()

        // Then
        XCTAssertEqual(provider.presentRatingRequestCallCount, 1)
    }

    func testGivenCurrentVersionAlreadyPromptedWhenRecordingMoreImprovementsThenRatingIsNotRequestedAgain() {
        // Given
        let suiteName = "StoreReviewServiceTests.alreadyPrompted"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let provider = MockRatingServiceProvider()
        let service = StoreReviewService(userDefaults: defaults, ratingProvider: provider)

        // When
        for _ in 0..<6 {
            service.recordBestScoreImprovementAndRequestIfEligible()
        }

        // Then
        XCTAssertEqual(provider.presentRatingRequestCallCount, 1)
    }
}
