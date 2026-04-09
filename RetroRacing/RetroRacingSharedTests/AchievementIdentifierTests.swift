//
//  AchievementIdentifierTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 04/04/2026.
//

import Foundation
import XCTest

@testable import RetroRacingShared

final class AchievementIdentifierTests: XCTestCase {
    func testGivenAllAchievementIdentifiersWhenCheckingPrefixThenAllUseCanonicalAchievementPrefix() {
        let prefix = AchievementIdentifier.achievementIdentifierPrefix + "."
        for id in AchievementIdentifier.allCases {
            XCTAssertTrue(id.rawValue.hasPrefix(prefix), "Unexpected raw value: \(id.rawValue)")
        }
    }

    func testGivenAllAchievementIdentifiersWhenCheckingLengthThenAllAreWithinASCMaximum() {
        for id in AchievementIdentifier.allCases {
            XCTAssertLessThanOrEqual(
                id.rawValue.count,
                100,
                "Achievement ID exceeded 100 characters: \(id.rawValue)"
            )
        }
    }

    func testGivenAllAchievementIdentifiersWhenCheckingLongestThenMatchesExpectedCurrentMaximum() {
        let longestLength = AchievementIdentifier.allCases.map { $0.rawValue.count }.max()
        XCTAssertEqual(longestLength, 70)
    }

    func testGivenStoredRawValueWhenResolvingThenOnlyCanonicalIdentifiersAreAccepted() {
        XCTAssertNil(AchievementIdentifier.resolvedFromStoredRawValue(""))
        XCTAssertNil(AchievementIdentifier.resolvedFromStoredRawValue("ach.control.tap"))
        XCTAssertEqual(
            AchievementIdentifier.resolvedFromStoredRawValue(
                "com.accessibilityUpTo11.RetroRacing.achievement.event.gaad.assistive"
            ),
            .eventGAADAssistive
        )
    }
}
