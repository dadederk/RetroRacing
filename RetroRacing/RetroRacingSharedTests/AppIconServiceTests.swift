//
//  AppIconServiceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 13/08/2026.
//

import XCTest
@testable import RetroRacingShared

@MainActor
final class AppIconServiceTests: XCTestCase {
    func testGivenSupportedServiceWhenChangingAndRefreshingThenSystemStateIsAuthoritative() async throws {
        // Given
        let changer = TestAppIconChanger(supportsAlternateIcons: true)
        let service = makeService(changer: changer)

        // When / Then
        try await service.changeIcon(to: .pocket)

        XCTAssertEqual(changer.requestedNames, ["RetroRapidPocket"])
        XCTAssertEqual(service.currentIconID, .pocket)
        XCTAssertNil(service.changingIconID)

        changer.alternateIconName = "RetroRapidDisc"
        service.refreshCurrentIcon()
        XCTAssertEqual(service.currentIconID, .disc)

        try await service.changeIcon(to: .classic)
        XCTAssertNil(changer.requestedNames.last ?? "unexpected")
        XCTAssertEqual(service.currentIconID, .classic)
    }

    func testGivenPlatformFailureWhenChangingThenSelectionAndProgressRecover() async {
        // Given
        let changer = TestAppIconChanger(supportsAlternateIcons: true)
        changer.failure = TestFailure.expected
        let service = makeService(changer: changer)

        // When / Then
        do {
            try await service.changeIcon(to: .pocket)
            XCTFail("Expected the platform failure to propagate")
        } catch {
            XCTAssertEqual(error as? TestFailure, .expected)
        }

        XCTAssertEqual(service.currentIconID, .classic)
        XCTAssertNil(service.changingIconID)
    }

    func testGivenConfiguredPlatformReportingUnsupportedWhenChangingThenSystemRequestIsAuthoritative() async throws {
        // Given
        let changer = TestAppIconChanger(supportsAlternateIcons: false)
        let service = AppIconService(
            changer: changer,
            isGalleryPlatformEnabled: true,
            availableThemeIDsProvider: releasedThemeIDs
        )

        // When
        try await service.changeIcon(to: .lcd)

        // Then
        XCTAssertEqual(changer.requestedNames, ["RetroRapidLCD"])
        XCTAssertEqual(service.currentIconID, .lcd)
        XCTAssertFalse(service.supportsAlternateIcons)
    }

    func testGivenUnconfiguredServiceWhenChangingThenRequestIsRejected() async {
        // Given
        let unconfigured = AppIconService(
            changer: TestAppIconChanger(supportsAlternateIcons: true),
            isGalleryPlatformEnabled: false,
            availableThemeIDsProvider: releasedThemeIDs
        )

        // When / Then
        XCTAssertFalse(unconfigured.isGalleryAvailable)
        await XCTAssertAppIconError(.unsupported) {
            try await unconfigured.changeIcon(to: .lcd)
        }
    }

    func testGivenPlatformConfigurationWhenCheckingGalleryThenItDeterminesAvailability() {
        // Given
        let cases: [(isGalleryPlatformEnabled: Bool, expected: Bool)] = [
            (false, false),
            (true, true),
        ]

        // When / Then
        for testCase in cases {
            let service = AppIconService(
                changer: TestAppIconChanger(supportsAlternateIcons: false),
                isGalleryPlatformEnabled: testCase.isGalleryPlatformEnabled,
                availableThemeIDsProvider: releasedThemeIDs
            )

            XCTAssertEqual(
                service.isGalleryAvailable,
                testCase.expected,
                "Expected platform=\(testCase.isGalleryPlatformEnabled)"
            )
        }
    }

    func testGivenConfiguredPlatformWithoutSystemSupportWhenRefreshingThenGalleryRemainsVisible() {
        // Given
        let changer = TestAppIconChanger(supportsAlternateIcons: false)
        let service = makeService(changer: changer)
        XCTAssertTrue(service.isGalleryAvailable)
        XCTAssertFalse(service.supportsAlternateIcons)

        // When
        changer.supportsAlternateIcons = true
        service.refreshSystemState()

        // Then
        XCTAssertTrue(service.supportsAlternateIcons)
        XCTAssertTrue(service.isGalleryAvailable)
    }

    func testGivenStaleUnsupportedSnapshotWhenChangingAfterUIKitBecomesReadyThenRequestSucceeds() async throws {
        // Given
        let changer = TestAppIconChanger(supportsAlternateIcons: false)
        let service = makeService(changer: changer)
        changer.supportsAlternateIcons = true

        // When
        try await service.changeIcon(to: .pocket)

        // Then
        XCTAssertTrue(service.supportsAlternateIcons)
        XCTAssertEqual(changer.requestedNames, ["RetroRapidPocket"])
        XCTAssertEqual(service.currentIconID, .pocket)
    }

    func testGivenAlternateInstalledOnUnconfiguredPlatformWhenInitializedThenInstalledIconIsPreserved() {
        // Given
        let changer = TestAppIconChanger(
            supportsAlternateIcons: true,
            alternateIconName: "RetroRapidCRT"
        )
        let service = AppIconService(
            changer: changer,
            isGalleryPlatformEnabled: false,
            availableThemeIDsProvider: releasedThemeIDs
        )

        // When / Then
        XCTAssertFalse(service.isGalleryAvailable)
        XCTAssertEqual(service.currentIconID, .crt)
        XCTAssertTrue(changer.requestedNames.isEmpty)
    }

    func testGivenFutureIconIsNotReleasedWhenSelectingThenRequestIsRejectedButInstalledIconIsPreserved() async {
        // Given
        let changer = TestAppIconChanger(
            supportsAlternateIcons: true,
            alternateIconName: "RetroRapidDisc"
        )
        let service = makeService(changer: changer)

        // When / Then
        XCTAssertEqual(service.currentIconID, .disc)
        XCTAssertFalse(service.availableOptions.contains { $0.id == .disc })
        await XCTAssertAppIconError(.unavailableIcon) {
            try await service.changeIcon(to: .polygon)
        }
        XCTAssertEqual(service.currentIconID, .disc)
        XCTAssertTrue(changer.requestedNames.isEmpty)
    }

    func testGivenChangeInProgressWhenSelectingAgainThenRepeatedRequestIsRejected() async throws {
        // Given
        let changer = TestAppIconChanger(supportsAlternateIcons: true)
        changer.shouldSuspend = true
        let changeStarted = expectation(description: "The first icon change reached the platform adapter")
        changer.onChangeStarted = { changeStarted.fulfill() }
        let service = makeService(changer: changer)
        let firstChange = Task {
            try await service.changeIcon(to: .cartridge)
        }
        await fulfillment(of: [changeStarted], timeout: 1)

        // When / Then
        await XCTAssertAppIconError(.changeInProgress) {
            try await service.changeIcon(to: .disc)
        }

        changer.resumeChange()
        try await firstChange.value
        XCTAssertEqual(service.currentIconID, .cartridge)
    }

    private func makeService(changer: TestAppIconChanger) -> AppIconService {
        AppIconService(
            changer: changer,
            isGalleryPlatformEnabled: true,
            availableThemeIDsProvider: releasedThemeIDs
        )
    }

    private func releasedThemeIDs() -> Set<ThemeID> {
        [.pocket, .lcd, .eightBit, .sixteenBit]
    }

    private func XCTAssertAppIconError(
        _ expected: AppIconServiceError,
        operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected)")
        } catch {
            XCTAssertEqual(error as? AppIconServiceError, expected)
        }
    }
}

@MainActor
private final class TestAppIconChanger: AppIconChanging {
    var supportsAlternateIcons: Bool
    var alternateIconName: String?
    var requestedNames: [String?] = []
    var failure: Error?
    var shouldSuspend = false
    var onChangeStarted: (() -> Void)?
    private var continuation: CheckedContinuation<Void, Error>?

    init(supportsAlternateIcons: Bool, alternateIconName: String? = nil) {
        self.supportsAlternateIcons = supportsAlternateIcons
        self.alternateIconName = alternateIconName
    }

    func setAlternateIconName(_ alternateIconName: String?) async throws {
        requestedNames.append(alternateIconName)
        onChangeStarted?()
        if let failure {
            throw failure
        }
        if shouldSuspend {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        }
        self.alternateIconName = alternateIconName
    }

    func resumeChange() {
        shouldSuspend = false
        continuation?.resume()
        continuation = nil
    }
}

private enum TestFailure: Error, Equatable {
    case expected
}
