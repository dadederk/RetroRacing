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

    func testRequestRatingCallsProviderAndRecordsPrompt() {
        let defaults = UserDefaults.standard
        let key = "StoreReview.lastPromptDate"
        defaults.removeObject(forKey: key)
        defer { defaults.removeObject(forKey: key) }

        let provider = MockRatingServiceProvider()
        let service = StoreReviewService(userDefaults: defaults, ratingProvider: provider)

        service.requestRating()

        XCTAssertEqual(provider.presentRatingRequestCallCount, 1)
        XCTAssertNotNil(defaults.object(forKey: key))
    }

    func testCheckAndRequestRatingDoesNotCallWhenScoreBelowThreshold() {
        let provider = MockRatingServiceProvider()
        let service = StoreReviewService(userDefaults: .standard, ratingProvider: provider)

        service.checkAndRequestRating(score: 100)

        XCTAssertEqual(provider.presentRatingRequestCallCount, 0)
    }

    func testRecordGamePlayedIncrementsCount() {
        let defaults = UserDefaults.standard
        let key = "StoreReview.gamesPlayed"
        defaults.removeObject(forKey: key)
        defer { defaults.removeObject(forKey: key) }

        let provider = MockRatingServiceProvider()
        let service = StoreReviewService(userDefaults: defaults, ratingProvider: provider)

        service.recordGamePlayed()
        service.recordGamePlayed()

        XCTAssertEqual(defaults.integer(forKey: key), 2)
    }
}
