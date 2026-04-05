//
//  ChallengeIdentifierTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 04/04/2026.
//

import Foundation
import XCTest

@testable import RetroRacingShared

final class ChallengeIdentifierTests: XCTestCase {
    func testAllIdentifiersUseBundlePrefixedFormat() {
        let prefix = ChallengeIdentifier.challengeIdentifierPrefix + "."
        for id in ChallengeIdentifier.allCases {
            XCTAssertTrue(id.rawValue.hasPrefix(prefix), "Unexpected raw value: \(id.rawValue)")
        }
    }

    func testDecodesLegacyRawValuesFromJSON() throws {
        guard let legacyJSON = #"["ach.run.overtakes.0100","ach.total.overtakes.001k"]"#.data(using: .utf8) else {
            XCTFail("Failed to encode legacy challenge identifiers as UTF-8 JSON data")
            return
        }
        let decoded = try JSONDecoder().decode([ChallengeIdentifier].self, from: legacyJSON)
        XCTAssertEqual(decoded, [.runOvertakes100, .totalOvertakes1k])
    }

    func testResolvedFromStoredRawValueAcceptsLegacyStrings() {
        XCTAssertEqual(ChallengeIdentifier.resolvedFromStoredRawValue("ach.control.tap"), .controlTap)
        XCTAssertNil(ChallengeIdentifier.resolvedFromStoredRawValue(""))
        XCTAssertEqual(
            ChallengeIdentifier.resolvedFromStoredRawValue(
                "com.accessibilityUpTo11.RetroRacing.ach.event.gaad.assistive"
            ),
            .eventGAADAssistive
        )
    }
}
