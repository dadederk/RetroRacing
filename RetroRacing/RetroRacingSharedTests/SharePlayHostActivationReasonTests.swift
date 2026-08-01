//
//  SharePlayHostActivationReasonTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 31/07/2026.
//

import XCTest
@testable import RetroRacingShared

final class SharePlayHostActivationReasonTests: XCTestCase {
    func testGivenActivationReasonsWhenReadingRawValuesThenLogStringsStayStable() {
        // Given
        let expectedRawValues: [SharePlayHostActivationReason: String] = [
            .menuRequest: "menu_request",
            .eligibleMenuRequest: "eligible_menu_request",
            .sharingControllerHandoffRecovery: "sharing_controller_handoff_recovery",
            .staleActivationRequest: "stale_activation_request",
            .sharingControllerDismissed: "sharing_controller_dismissed",
            .sessionHandoffTimeout: "session_handoff_timeout",
            .hostActivationRejected: "host_activation_rejected",
            .sharePlayUnavailable: "shareplay_unavailable",
            .sharePlayStateArrived: "shareplay_state_arrived",
            .directActivationFailed: "direct_activation_failed",
            .handoffRecoveryFailed: "handoff_recovery_failed",
            .sharingControllerSucceeded: "sharing_controller_succeeded",
            .leaveWithoutSession: "leave_without_session"
        ]

        // When
        let rawValues = Dictionary(
            uniqueKeysWithValues: SharePlayHostActivationReason.allCases.map { ($0, $0.rawValue) }
        )

        // Then
        XCTAssertEqual(rawValues, expectedRawValues)
    }
}
