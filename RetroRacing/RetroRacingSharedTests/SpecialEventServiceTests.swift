//
//  SpecialEventServiceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 09/04/2026.
//

import XCTest
@testable import RetroRacingShared

final class SpecialEventServiceTests: XCTestCase {

    // Miami Grand Prix 2026: May 1–3 (UTC).
    // Active window: [May 1 00:00 UTC, May 4 00:00 UTC)
    private var service: DateRangeSpecialEventService!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        try super.setUpWithError()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt

        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 1)))
        let inclusiveEnd = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3)))
        service = DateRangeSpecialEventService(
            name: "Miami Grand Prix",
            startDate: start,
            inclusiveEndDate: inclusiveEnd
        )
    }

    override func tearDown() {
        service = nil
        calendar = nil
        super.tearDown()
    }

    // MARK: - isEventActive

    func testGivenDateBeforeEventWhenCheckingActiveThenReturnsFalse() throws {
        // Given
        let dateBeforeEvent = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 30, hour: 23, minute: 59)))

        // When
        let isActive = service.isEventActive(on: dateBeforeEvent)

        // Then
        XCTAssertFalse(isActive)
    }

    func testGivenExactStartDateWhenCheckingActiveThenReturnsTrue() throws {
        // Given
        let exactStart = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 1, hour: 0, minute: 0)))

        // When
        let isActive = service.isEventActive(on: exactStart)

        // Then
        XCTAssertTrue(isActive)
    }

    func testGivenMidEventDateWhenCheckingActiveThenReturnsTrue() throws {
        // Given
        let midEvent = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 2, hour: 14, minute: 30)))

        // When
        let isActive = service.isEventActive(on: midEvent)

        // Then
        XCTAssertTrue(isActive)
    }

    func testGivenLastEventDayWhenCheckingActiveThenReturnsTrue() throws {
        // Given
        let lastDay = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3, hour: 23, minute: 59)))

        // When
        let isActive = service.isEventActive(on: lastDay)

        // Then
        XCTAssertTrue(isActive)
    }

    func testGivenExactExclusiveEndDateWhenCheckingActiveThenReturnsFalse() throws {
        // Given — May 4 00:00 UTC is the exclusive upper bound; event has ended
        let exclusiveEnd = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 4, hour: 0, minute: 0)))

        // When
        let isActive = service.isEventActive(on: exclusiveEnd)

        // Then
        XCTAssertFalse(isActive)
    }

    func testGivenDateAfterEventWhenCheckingActiveThenReturnsFalse() throws {
        // Given
        let afterEvent = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 10)))

        // When
        let isActive = service.isEventActive(on: afterEvent)

        // Then
        XCTAssertFalse(isActive)
    }

    // MARK: - eventInfo

    func testGivenActiveDateWhenRequestingInfoThenReturnsEventInfo() throws {
        // Given
        let duringEvent = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 2)))

        // When
        let info = service.eventInfo(on: duringEvent)

        // Then
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.name, "Miami Grand Prix")
    }

    func testGivenInactiveDateWhenRequestingInfoThenReturnsNil() throws {
        // Given
        let afterEvent = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 5)))

        // When
        let info = service.eventInfo(on: afterEvent)

        // Then
        XCTAssertNil(info)
    }

    func testGivenActiveDateWhenRequestingInfoThenInclusiveEndDateIsLastEventDay() throws {
        // Given
        let duringEvent = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 1)))
        let expectedInclusiveEnd = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 3)))

        // When
        let info = service.eventInfo(on: duringEvent)

        // Then — inclusiveEndDate should be May 3, not May 4
        XCTAssertEqual(info?.inclusiveEndDate, expectedInclusiveEnd)
    }

    // MARK: - Play recording bypass

    func testGivenEventActiveWhenCheckingWhetherToSkipRecordingThenShouldSkip() throws {
        // Given
        let duringEvent = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 2)))

        // When / Then — event active means recording should be skipped
        XCTAssertTrue(service.isEventActive(on: duringEvent))
    }

    func testGivenEventInactiveWhenCheckingWhetherToSkipRecordingThenShouldNotSkip() throws {
        // Given
        let afterEvent = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 4)))

        // When / Then — event not active means recording should proceed normally
        XCTAssertFalse(service.isEventActive(on: afterEvent))
    }
}
