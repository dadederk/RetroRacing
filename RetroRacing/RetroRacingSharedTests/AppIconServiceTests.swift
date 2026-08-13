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
        let changer = TestAppIconChanger(supportsAlternateIcons: true)
        let service = makeService(changer: changer)

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
        let changer = TestAppIconChanger(supportsAlternateIcons: true)
        changer.failure = TestFailure.expected
        let service = makeService(changer: changer)

        do {
            try await service.changeIcon(to: .polygon)
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
            featureFlag: enabledFeatureFlag(),
            isGalleryPlatformEnabled: true
        )

        // When
        try await service.changeIcon(to: .lcd)

        // Then
        XCTAssertEqual(changer.requestedNames, ["RetroRapidLCD"])
        XCTAssertEqual(service.currentIconID, .lcd)
        XCTAssertFalse(service.supportsAlternateIcons)
    }

    func testGivenDisabledOrUnconfiguredServiceWhenChangingThenRequestIsRejected() async {
        // Given
        let disabled = AppIconService(
            changer: TestAppIconChanger(supportsAlternateIcons: true),
            featureFlag: FixedAppIconFeatureFlag(isEnabled: false),
            isGalleryPlatformEnabled: true
        )
        let unconfigured = AppIconService(
            changer: TestAppIconChanger(supportsAlternateIcons: true),
            featureFlag: enabledFeatureFlag(),
            isGalleryPlatformEnabled: false
        )

        // When / Then
        XCTAssertFalse(disabled.isGalleryAvailable)
        await XCTAssertAppIconError(.featureDisabled) {
            try await disabled.changeIcon(to: .lcd)
        }
        XCTAssertFalse(unconfigured.isGalleryAvailable)
        await XCTAssertAppIconError(.unsupported) {
            try await unconfigured.changeIcon(to: .lcd)
        }
    }

    func testGivenRolloutAndConfiguredPlatformWhenCheckingGalleryThenBothAreRequired() {
        let cases: [(isGalleryPlatformEnabled: Bool, isFeatureEnabled: Bool, expected: Bool)] = [
            (false, false, false),
            (false, true, false),
            (true, false, false),
            (true, true, true),
        ]

        for testCase in cases {
            let service = AppIconService(
                changer: TestAppIconChanger(supportsAlternateIcons: false),
                featureFlag: FixedAppIconFeatureFlag(isEnabled: testCase.isFeatureEnabled),
                isGalleryPlatformEnabled: testCase.isGalleryPlatformEnabled
            )

            XCTAssertEqual(
                service.isGalleryAvailable,
                testCase.expected,
                "Expected platform=\(testCase.isGalleryPlatformEnabled), feature=\(testCase.isFeatureEnabled)"
            )
        }
    }

    func testGivenConfiguredPlatformWithoutSystemSupportWhenRefreshingThenGalleryRemainsVisible() {
        let changer = TestAppIconChanger(supportsAlternateIcons: false)
        let service = makeService(changer: changer)
        XCTAssertTrue(service.isGalleryAvailable)
        XCTAssertFalse(service.supportsAlternateIcons)

        changer.supportsAlternateIcons = true
        service.refreshSystemState()

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

    func testGivenAlternateInstalledWhenFlagIsDisabledThenInstalledIconIsPreserved() async throws {
        let changer = TestAppIconChanger(
            supportsAlternateIcons: true,
            alternateIconName: "RetroRapidCRT"
        )
        let service = AppIconService(
            changer: changer,
            featureFlag: FixedAppIconFeatureFlag(isEnabled: true, allowsChanges: true),
            isGalleryPlatformEnabled: true
        )

        service.setFeatureEnabled(false)

        XCTAssertFalse(service.isGalleryAvailable)
        XCTAssertEqual(service.currentIconID, .crt)
        XCTAssertTrue(changer.requestedNames.isEmpty)
    }

    func testGivenChangeInProgressWhenSelectingAgainThenRepeatedRequestIsRejected() async throws {
        let changer = TestAppIconChanger(supportsAlternateIcons: true)
        changer.shouldSuspend = true
        let changeStarted = expectation(description: "The first icon change reached the platform adapter")
        changer.onChangeStarted = { changeStarted.fulfill() }
        let service = makeService(changer: changer)
        let firstChange = Task {
            try await service.changeIcon(to: .cartridge)
        }
        await fulfillment(of: [changeStarted], timeout: 1)

        await XCTAssertAppIconError(.changeInProgress) {
            try await service.changeIcon(to: .disc)
        }

        changer.resumeChange()
        try await firstChange.value
        XCTAssertEqual(service.currentIconID, .cartridge)
    }

    func testGivenSuspendedCallbackWhenSystemAppliedIconAndAppActivatesThenChangeReconciles() async throws {
        // Given
        let changer = TestAppIconChanger(supportsAlternateIcons: true)
        changer.shouldSuspend = true
        let changeStarted = expectation(description: "The icon request reached the platform adapter")
        let callbackFinished = expectation(description: "The late platform callback finished")
        changer.onChangeStarted = { changeStarted.fulfill() }
        changer.onChangeFinished = { callbackFinished.fulfill() }
        let service = makeService(changer: changer)
        let change = Task {
            try await service.changeIcon(to: .disc)
        }
        await fulfillment(of: [changeStarted], timeout: 1)
        changer.alternateIconName = "RetroRapidDisc"

        // When
        service.reconcileSystemStateAfterActivation()

        // Then
        try await change.value
        XCTAssertEqual(service.currentIconID, .disc)
        XCTAssertNil(service.changingIconID)
        changer.resumeChange()
        await fulfillment(of: [callbackFinished], timeout: 1)
    }

    func testGivenSuspendedCallbackWhenSystemStateIsUnchangedAndAppActivatesThenRetryIsAvailable() async throws {
        // Given
        let changer = TestAppIconChanger(supportsAlternateIcons: true)
        changer.shouldSuspend = true
        let changeStarted = expectation(description: "The icon request reached the platform adapter")
        let callbackFinished = expectation(description: "The late platform callback finished")
        changer.onChangeStarted = { changeStarted.fulfill() }
        changer.onChangeFinished = { callbackFinished.fulfill() }
        let service = makeService(changer: changer)
        let change = Task {
            try await service.changeIcon(to: .cartridge)
        }
        await fulfillment(of: [changeStarted], timeout: 1)

        // When
        service.reconcileSystemStateAfterActivation()

        // Then
        await XCTAssertAppIconError(.systemStateUnchanged) {
            try await change.value
        }
        XCTAssertEqual(service.currentIconID, .classic)
        XCTAssertNil(service.changingIconID)

        changer.resumeChange()
        await fulfillment(of: [callbackFinished], timeout: 1)
        changer.onChangeStarted = nil
        changer.onChangeFinished = nil
        try await service.changeIcon(to: .disc)
        XCTAssertEqual(service.currentIconID, .disc)
    }

    private func enabledFeatureFlag() -> FixedAppIconFeatureFlag {
        FixedAppIconFeatureFlag(isEnabled: true)
    }

    private func makeService(changer: TestAppIconChanger) -> AppIconService {
        AppIconService(
            changer: changer,
            featureFlag: enabledFeatureFlag(),
            isGalleryPlatformEnabled: true
        )
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
    var onChangeFinished: (() -> Void)?
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
        onChangeFinished?()
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
