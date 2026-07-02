//
//  GameCenterAchievementMetadataServiceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 26/06/2026.
//

import XCTest
@testable import RetroRacingShared

final class GameCenterAchievementMetadataServiceTests: XCTestCase {

    func testGivenUnauthenticatedProviderWhenLoadingArtworkThenReturnsNil() async {
        // Given
        let service = GameCenterAchievementMetadataService(isAuthenticatedProvider: { false })

        // When
        let artwork = await service.loadArtwork(for: "com.example.achievement")

        // Then
        XCTAssertNil(artwork)
    }

    func testGivenNoOpServiceWhenLoadingArtworkThenReturnsNil() async {
        // Given
        let service = NoOpAchievementMetadataService()

        // When
        let artwork = await service.loadArtwork(for: "com.example.achievement")

        // Then
        XCTAssertNil(artwork)
    }

    func testGivenInvalidateWhenLoadingArtworkAfterAuthChangeThenDoesNotReturnStaleCache() async {
        // Given
        let service = GameCenterAchievementMetadataService(isAuthenticatedProvider: { false })

        // When
        await service.invalidate()
        let artwork = await service.loadArtwork(for: "com.example.achievement")

        // Then
        XCTAssertNil(artwork)
    }
}
