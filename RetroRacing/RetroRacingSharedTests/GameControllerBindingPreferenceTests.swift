//
//  GameControllerBindingPreferenceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 2026-03-02.
//

import XCTest
@testable import RetroRacingShared

final class GameControllerBindingPreferenceTests: XCTestCase {
    private static let suiteName = "test.GameControllerBindingPreferenceTests"
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: Self.suiteName)!
        userDefaults.removePersistentDomain(forName: Self.suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: Self.suiteName)
        userDefaults = nil
        super.tearDown()
    }

    func testGivenNoStoredProfileWhenLoadingThenDefaultProfileIsReturned() {
        // Given - nothing stored

        // When
        let profile = GameControllerBindingPreference.currentProfile(from: userDefaults)

        // Then
        XCTAssertEqual(profile, .default)
        XCTAssertEqual(profile.leftButton, .dpadLeft)
        XCTAssertEqual(profile.rightButton, .dpadRight)
        XCTAssertEqual(profile.pauseButton, .menu)
    }

    func testGivenProfileWhenSavingAndLoadingThenProfileIsPreserved() {
        // Given
        let original = GameControllerBindingProfile(
            leftButton: .a,
            rightButton: .b,
            pauseButton: .menu
        )

        // When
        GameControllerBindingPreference.setProfile(original, in: userDefaults)
        let loaded = GameControllerBindingPreference.currentProfile(from: userDefaults)

        // Then
        XCTAssertEqual(loaded, original)
    }

    func testGivenStoredProfileWhenOverwritingThenLatestProfileIsReturned() {
        // Given
        let first = GameControllerBindingProfile(
            leftButton: .a,
            rightButton: .none,
            pauseButton: .none
        )
        let second = GameControllerBindingProfile(
            leftButton: .x,
            rightButton: .y,
            pauseButton: .leftShoulder
        )
        GameControllerBindingPreference.setProfile(first, in: userDefaults)

        // When
        GameControllerBindingPreference.setProfile(second, in: userDefaults)
        let loaded = GameControllerBindingPreference.currentProfile(from: userDefaults)

        // Then
        XCTAssertEqual(loaded, second)
    }

    func testGivenCorruptedStoredDataWhenLoadingThenDefaultProfileIsReturned() {
        // Given
        userDefaults.set(Data([0xFF, 0xFE]), forKey: GameControllerBindingPreference.storageKey)

        // When
        let profile = GameControllerBindingPreference.currentProfile(from: userDefaults)

        // Then
        XCTAssertEqual(profile, .default)
    }

    func testGivenDpadDefaultsWhenSavingAndLoadingThenDpadButtonsArePreserved() {
        // Given
        let profile = GameControllerBindingProfile(
            leftButton: .dpadLeft,
            rightButton: .dpadRight,
            pauseButton: .menu
        )

        // When
        GameControllerBindingPreference.setProfile(profile, in: userDefaults)
        let loaded = GameControllerBindingPreference.currentProfile(from: userDefaults)

        // Then
        XCTAssertEqual(loaded.leftButton, .dpadLeft)
        XCTAssertEqual(loaded.rightButton, .dpadRight)
    }
}
