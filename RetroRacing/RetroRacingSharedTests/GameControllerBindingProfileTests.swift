//
//  GameControllerBindingProfileTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 2026-03-02.
//

import XCTest
@testable import RetroRacingShared

final class GameControllerBindingProfileTests: XCTestCase {

    // MARK: - Default profile

    func testGivenDefaultProfileWhenCheckingButtonsThenDpadAndMenuAreSet() {
        // Given / When
        let profile = GameControllerBindingProfile.default

        // Then
        XCTAssertEqual(profile.leftButton, .dpadLeft)
        XCTAssertEqual(profile.rightButton, .dpadRight)
        XCTAssertEqual(profile.pauseButton, .menu)
    }

    // MARK: - action(for:)

    func testGivenNoneButtonWhenQueryingActionThenNilIsReturned() {
        // Given
        let profile = GameControllerBindingProfile.default

        // When
        let action = profile.action(for: .none)

        // Then
        XCTAssertNil(action)
    }

    func testGivenDefaultProfileWhenQueryingDpadLeftThenMoveLeftIsReturned() {
        // Given / When
        let action = GameControllerBindingProfile.default.action(for: .dpadLeft)

        // Then
        XCTAssertEqual(action, .moveLeft)
    }

    func testGivenDefaultProfileWhenQueryingDpadRightThenMoveRightIsReturned() {
        // Given / When
        let action = GameControllerBindingProfile.default.action(for: .dpadRight)

        // Then
        XCTAssertEqual(action, .moveRight)
    }

    func testGivenDefaultProfileWhenQueryingMenuThenPauseResumeIsReturned() {
        // Given / When
        let action = GameControllerBindingProfile.default.action(for: .menu)

        // Then
        XCTAssertEqual(action, .pauseResume)
    }

    func testGivenAssignedButtonWhenQueryingActionThenCorrectActionIsReturned() {
        // Given
        let profile = GameControllerBindingProfile(
            leftButton: .a,
            rightButton: .b,
            pauseButton: .x
        )

        // Then
        XCTAssertEqual(profile.action(for: .a), .moveLeft)
        XCTAssertEqual(profile.action(for: .b), .moveRight)
        XCTAssertEqual(profile.action(for: .x), .pauseResume)
    }

    func testGivenUnassignedButtonWhenQueryingActionThenNilIsReturned() {
        // Given
        let profile = GameControllerBindingProfile(
            leftButton: .a,
            rightButton: .none,
            pauseButton: .none
        )

        // When
        let action = profile.action(for: .b)

        // Then
        XCTAssertNil(action)
    }

    // MARK: - settingLeft / settingRight / settingPause

    func testGivenDefaultProfileWhenSettingLeftButtonThenLeftButtonIsUpdated() {
        // Given
        let profile = GameControllerBindingProfile.default

        // When
        let updated = profile.settingLeft(.a)

        // Then
        XCTAssertEqual(updated.leftButton, .a)
        XCTAssertEqual(updated.rightButton, .dpadRight)
        XCTAssertEqual(updated.pauseButton, .menu)
    }

    func testGivenDefaultProfileWhenSettingRightButtonThenRightButtonIsUpdated() {
        // Given
        let profile = GameControllerBindingProfile.default

        // When
        let updated = profile.settingRight(.b)

        // Then
        XCTAssertEqual(updated.rightButton, .b)
        XCTAssertEqual(updated.leftButton, .dpadLeft)
    }

    func testGivenDefaultProfileWhenSettingPauseButtonThenPauseButtonIsUpdated() {
        // Given
        let profile = GameControllerBindingProfile.default

        // When
        let updated = profile.settingPause(.y)

        // Then
        XCTAssertEqual(updated.pauseButton, .y)
        XCTAssertEqual(updated.leftButton, .dpadLeft)
        XCTAssertEqual(updated.rightButton, .dpadRight)
    }

    // MARK: - Conflict resolution

    func testGivenButtonAssignedToLeftWhenAssigningSameButtonToRightThenLeftIsCleared() {
        // Given
        let profile = GameControllerBindingProfile.default.settingLeft(.a)

        // When
        let updated = profile.settingRight(.a)

        // Then
        XCTAssertEqual(updated.rightButton, .a)
        XCTAssertEqual(updated.leftButton, .none, "Conflict: 'a' moved from left to right")
        XCTAssertEqual(updated.pauseButton, .menu)
    }

    func testGivenButtonAssignedToRightWhenAssigningSameButtonToPauseThenRightIsCleared() {
        // Given
        let profile = GameControllerBindingProfile.default.settingRight(.b)

        // When
        let updated = profile.settingPause(.b)

        // Then
        XCTAssertEqual(updated.pauseButton, .b)
        XCTAssertEqual(updated.rightButton, .none, "Conflict: 'b' moved from right to pause")
    }

    func testGivenButtonAssignedToPauseWhenAssigningSameButtonToLeftThenPauseIsCleared() {
        // Given
        let profile = GameControllerBindingProfile.default.settingPause(.x)

        // When
        let updated = profile.settingLeft(.x)

        // Then
        XCTAssertEqual(updated.leftButton, .x)
        XCTAssertEqual(updated.pauseButton, .none, "Conflict: 'x' moved from pause to left")
    }

    func testGivenButtonAssignedToLeftWhenReassigningLeftToSameButtonThenNoConflictOccurs() {
        // Given
        let profile = GameControllerBindingProfile.default.settingLeft(.a)

        // When
        let updated = profile.settingLeft(.a)

        // Then
        XCTAssertEqual(updated.leftButton, .a, "Re-assigning same button to same action should preserve it")
    }

    func testGivenNoneButtonWhenAssigningToAnyActionThenNoConflictOccurs() {
        // Given
        let profile = GameControllerBindingProfile(
            leftButton: .a,
            rightButton: .b,
            pauseButton: .x
        )

        // When
        let updated = profile.settingLeft(.none)

        // Then
        XCTAssertEqual(updated.leftButton, .none)
        XCTAssertEqual(updated.rightButton, .b, "Other buttons should be untouched when setting .none")
        XCTAssertEqual(updated.pauseButton, .x, "Other buttons should be untouched when setting .none")
    }

    func testGivenDpadDefaultWhenReassigningLeftToDpadRightThenConflictIsResolved() {
        // Given — default has dpadRight on rightButton
        let profile = GameControllerBindingProfile.default

        // When — assign dpadRight to left, which conflicts with rightButton
        let updated = profile.settingLeft(.dpadRight)

        // Then
        XCTAssertEqual(updated.leftButton, .dpadRight)
        XCTAssertEqual(updated.rightButton, .none, "Conflict: dpadRight moved from right to left")
    }

    // MARK: - Codable round-trip

    func testGivenProfileWhenEncodingAndDecodingThenProfileIsPreserved() throws {
        // Given
        let original = GameControllerBindingProfile(
            leftButton: .a,
            rightButton: .leftShoulder,
            pauseButton: .menu
        )

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GameControllerBindingProfile.self, from: data)

        // Then
        XCTAssertEqual(decoded, original)
    }

    func testGivenDefaultProfileWhenEncodingAndDecodingThenDefaultIsPreserved() throws {
        // Given
        let original = GameControllerBindingProfile.default

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GameControllerBindingProfile.self, from: data)

        // Then
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.leftButton, .dpadLeft)
        XCTAssertEqual(decoded.rightButton, .dpadRight)
        XCTAssertEqual(decoded.pauseButton, .menu)
    }
}
