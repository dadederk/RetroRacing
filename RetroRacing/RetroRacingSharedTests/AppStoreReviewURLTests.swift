//
//  AppStoreReviewURLTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 25/10/2026.
//

import XCTest
@testable import RetroRacingShared

final class AppStoreReviewURLTests: XCTestCase {
    func testGivenWriteReviewDestinationWhenResolvingURLThenItIncludesTheAppIDAndReviewAction() throws {
        let url = try XCTUnwrap(AppStoreReviewURL.writeReview)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertTrue(components.path.hasSuffix("/id6758641625"))
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "action", value: "write-review")])
    }

    func testGivenProductDestinationWhenResolvingURLThenItIncludesTheAppIDWithoutAReviewAction() throws {
        let url = try XCTUnwrap(AppStoreReviewURL.productPage)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertTrue(components.path.hasSuffix("/id6758641625"))
        XCTAssertNil(components.query)
    }
}
