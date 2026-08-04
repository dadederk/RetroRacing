//
//  GameAreaLayoutConfigurationTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 04/08/2026.
//

import SwiftUI
import XCTest
@testable import RetroRacingShared

final class GameAreaLayoutConfigurationTests: XCTestCase {
    func testGivenCompactLandscapeExpansionWhenCalculatingSideThenAppliesEdgePadding() {
        // Given
        let configuration = GameAreaLayoutConfiguration.resolve(
            policy: expandedCompactLandscapePolicy,
            topSafeAreaInset: 44
        )

        // When
        let side = configuration.side(for: CGSize(width: 393, height: 393))

        // Then
        XCTAssertEqual(side, 377)
    }

    func testGivenCompactLandscapeExpansionWhenResolvingConfigurationThenReappliesTopSafeArea() {
        // When
        let configuration = GameAreaLayoutConfiguration.resolve(
            policy: expandedCompactLandscapePolicy,
            topSafeAreaInset: 44
        )

        // Then
        XCTAssertTrue(configuration.reappliesTopSafeArea)
        XCTAssertEqual(configuration.topSafeAreaInset, 44)
    }

    func testGivenCompactLandscapeWithoutExpansionWhenCalculatingSideThenUsesFullAvailableSide() {
        // Given
        let configuration = GameAreaLayoutConfiguration.resolve(
            policy: GameLayoutPolicy.resolve(
                containerSize: CGSize(width: 852, height: 393),
                horizontalSizeClass: .regular,
                verticalSizeClass: .compact,
                platformSupportsTopSafeAreaExpansion: true,
                isScreenshotCapture: true
            ),
            topSafeAreaInset: 44
        )

        // When
        let side = configuration.side(for: CGSize(width: 393, height: 393))

        // Then
        XCTAssertEqual(side, 393)
    }

    func testGivenPortraitPolicyWhenResolvingConfigurationThenUsesStandardSizing() {
        // When
        let configuration = GameAreaLayoutConfiguration.resolve(
            policy: GameLayoutPolicy.resolve(
                containerSize: CGSize(width: 393, height: 852),
                horizontalSizeClass: .compact,
                verticalSizeClass: .regular,
                platformSupportsTopSafeAreaExpansion: true,
                isScreenshotCapture: false
            ),
            topSafeAreaInset: 44
        )

        // Then
        XCTAssertEqual(configuration, .standard)
    }

    func testGivenTinyAvailableSizeWhenCalculatingExpandedSideThenDoesNotReturnNegativeValue() {
        // Given
        let configuration = GameAreaLayoutConfiguration.resolve(
            policy: expandedCompactLandscapePolicy,
            topSafeAreaInset: 44
        )

        // When
        let side = configuration.side(for: CGSize(width: 10, height: 10))

        // Then
        XCTAssertEqual(side, 0)
    }

    func testGivenWidthLimitedExpandedLayoutWhenCalculatingSideThenPreservesUnexpandedSide() {
        // Given
        let configuration = GameAreaLayoutConfiguration.resolve(
            policy: expandedCompactLandscapePolicy,
            topSafeAreaInset: 44
        )

        // When
        let side = configuration.side(for: CGSize(width: 315, height: 375))

        // Then
        XCTAssertEqual(side, 315)
    }

    func testGivenCompactHeightPortraitWindowWhenResolvingPolicyThenTopSafeAreaIsPreserved() {
        // Given
        let containerSize = CGSize(width: 375, height: 667)

        // When
        let policy = GameLayoutPolicy.resolve(
            containerSize: containerSize,
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            platformSupportsTopSafeAreaExpansion: true,
            isScreenshotCapture: false
        )

        // Then
        XCTAssertEqual(policy.kind, .portrait)
        XCTAssertFalse(policy.expandsGameAreaIntoTopSafeArea)
    }

    func testGivenCompactLandscapeScreenshotWhenResolvingPolicyThenTopSafeAreaIsPreserved() {
        // When
        let policy = GameLayoutPolicy.resolve(
            containerSize: CGSize(width: 852, height: 393),
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            platformSupportsTopSafeAreaExpansion: true,
            isScreenshotCapture: true
        )

        // Then
        XCTAssertEqual(policy.kind, .compactLandscape)
        XCTAssertFalse(policy.expandsGameAreaIntoTopSafeArea)
    }

    func testGivenCompactLandscapeOnUnsupportedPlatformWhenResolvingPolicyThenTopSafeAreaIsPreserved() {
        // When
        let policy = GameLayoutPolicy.resolve(
            containerSize: CGSize(width: 852, height: 393),
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            platformSupportsTopSafeAreaExpansion: false,
            isScreenshotCapture: false
        )

        // Then
        XCTAssertEqual(policy.kind, .compactLandscape)
        XCTAssertFalse(policy.expandsGameAreaIntoTopSafeArea)
    }

    func testGivenCompactLandscapeOnIOSWhenResolvingPolicyThenTopSafeAreaExpands() {
        // When
        let policy = GameLayoutPolicy.resolve(
            containerSize: CGSize(width: 852, height: 393),
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            platformSupportsTopSafeAreaExpansion: true,
            isScreenshotCapture: false
        )

        // Then
        XCTAssertEqual(policy.kind, .compactLandscape)
        XCTAssertTrue(policy.expandsGameAreaIntoTopSafeArea)
    }

    private var expandedCompactLandscapePolicy: GameLayoutPolicy {
        GameLayoutPolicy.resolve(
            containerSize: CGSize(width: 852, height: 393),
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            platformSupportsTopSafeAreaExpansion: true,
            isScreenshotCapture: false
        )
    }
}
