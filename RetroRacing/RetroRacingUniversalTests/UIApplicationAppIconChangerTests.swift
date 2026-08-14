//
//  UIApplicationAppIconChangerTests.swift
//  RetroRacingUniversalTests
//
//  Created by Dani Devesa on 14/08/2026.
//

#if os(iOS)
import XCTest
import UIKit
@testable import RetroRacingUniversal

final class UIApplicationAppIconChangerTests: XCTestCase {
    private let pocketSystemName = "RetroRapidPocket"

    @MainActor
    func testGivenWithheldUIKitCallbackWhenSystemStateChangesThenAdapterCompletes() async throws {
        // Given
        let application = AppIconApplicationFake(behavior: .systemStateOnly)
        let adapter = makeAdapter(application: application)

        // When
        try await adapter.setAlternateIconName(pocketSystemName)

        // Then
        XCTAssertEqual(application.alternateIconName, pocketSystemName)
    }

    @MainActor
    func testGivenUIKitErrorWhenSystemStateMatchesThenAdapterTrustsSystemState() async throws {
        // Given
        let application = AppIconApplicationFake(behavior: .systemStateAndFailure)
        let adapter = makeAdapter(application: application)

        // When
        try await adapter.setAlternateIconName(pocketSystemName)

        // Then
        XCTAssertEqual(application.alternateIconName, pocketSystemName)
    }

    @MainActor
    func testGivenUIKitErrorBeforeDelayedSystemStateWhenStateMatchesThenAdapterCompletes() async throws {
        // Given
        let application = AppIconApplicationFake(behavior: .failure)
        let adapter = makeAdapter(application: application) { _ in
            application.reportAlternateIconName(self.pocketSystemName)
        }

        // When
        try await adapter.setAlternateIconName(pocketSystemName)

        // Then
        XCTAssertEqual(application.alternateIconName, pocketSystemName)
    }

    @MainActor
    func testGivenSuccessfulUIKitCompletionWhenSystemStateIsDelayedThenAdapterCompletes() async throws {
        // Given
        let application = AppIconApplicationFake(behavior: .success)
        let adapter = makeAdapter(application: application)

        // When
        try await adapter.setAlternateIconName(pocketSystemName)

        // Then
        XCTAssertNil(application.alternateIconName)
    }

    @MainActor
    func testGivenInactiveApplicationWhenConfirmationTakesLongerThanBudgetThenAdapterKeepsWaiting() async throws {
        // Given
        let application = AppIconApplicationFake(
            behavior: .noResult,
            applicationState: .inactive
        )
        var waitCount = 0
        let adapter = UIApplicationAppIconChanger(
            application: application,
            systemStatePollInterval: .zero,
            maximumActiveSystemStatePollCount: 1,
            maximumCompletionStatePollCount: 1,
            wait: { _ in
                waitCount += 1
                if waitCount == 3 {
                    application.reportAlternateIconName(self.pocketSystemName)
                    application.applicationState = .active
                }
            }
        )

        // When
        try await adapter.setAlternateIconName(pocketSystemName)

        // Then
        XCTAssertEqual(waitCount, 3)
        XCTAssertEqual(application.alternateIconName, pocketSystemName)
    }

    @MainActor
    func testGivenUIKitFailureWhenActiveSystemStateStaysUnchangedThenAdapterThrows() async {
        // Given
        let application = AppIconApplicationFake(behavior: .failure)
        let adapter = makeAdapter(application: application)

        // When / Then
        do {
            try await adapter.setAlternateIconName(pocketSystemName)
            XCTFail("Expected the UIKit failure to be propagated.")
        } catch {
            XCTAssertEqual(error as? AppIconApplicationFake.TestError, .requestFailed)
        }
    }

    @MainActor
    func testGivenNoCallbackOrStateChangeWhenActivePollingEndsThenAdapterTimesOut() async {
        // Given
        let application = AppIconApplicationFake(behavior: .noResult)
        let adapter = makeAdapter(application: application)

        // When / Then
        do {
            try await adapter.setAlternateIconName(pocketSystemName)
            XCTFail("Expected the bounded active-state wait to time out.")
        } catch {
            XCTAssertEqual(
                error as? UIApplicationAppIconChangerError,
                .systemStateTimedOut
            )
        }
    }

    @MainActor
    private func makeAdapter(
        application: AppIconApplicationFake,
        wait: @escaping @MainActor @Sendable (Duration) async throws -> Void = { _ in }
    ) -> UIApplicationAppIconChanger {
        UIApplicationAppIconChanger(
            application: application,
            systemStatePollInterval: .zero,
            maximumActiveSystemStatePollCount: 2,
            maximumCompletionStatePollCount: 2,
            wait: wait
        )
    }
}

@MainActor
private final class AppIconApplicationFake: UIApplicationAppIconChanging {
    enum Behavior {
        case systemStateOnly
        case systemStateAndFailure
        case success
        case failure
        case noResult
    }

    enum TestError: Error, Equatable {
        case requestFailed
    }

    let supportsAlternateIcons = true
    var applicationState: UIApplication.State
    private(set) var alternateIconName: String?
    private let behavior: Behavior

    init(
        behavior: Behavior,
        alternateIconName: String? = nil,
        applicationState: UIApplication.State = .active
    ) {
        self.behavior = behavior
        self.alternateIconName = alternateIconName
        self.applicationState = applicationState
    }

    func setAlternateIconName(
        _ alternateIconName: String?,
        completionHandler: (@MainActor @Sendable (Error?) -> Void)?
    ) {
        switch behavior {
        case .systemStateOnly:
            self.alternateIconName = alternateIconName
        case .systemStateAndFailure:
            self.alternateIconName = alternateIconName
            completionHandler?(TestError.requestFailed)
        case .success:
            completionHandler?(nil)
        case .failure:
            completionHandler?(TestError.requestFailed)
        case .noResult:
            break
        }
    }

    func reportAlternateIconName(_ alternateIconName: String?) {
        self.alternateIconName = alternateIconName
    }
}
#endif
