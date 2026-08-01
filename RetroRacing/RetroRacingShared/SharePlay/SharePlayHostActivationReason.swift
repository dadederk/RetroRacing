//
//  SharePlayHostActivationReason.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 31/07/2026.
//

import Foundation

/// Typed log/control reasons for the host-side SharePlay activation handoff.
public enum SharePlayHostActivationReason: String, Sendable, Equatable, CaseIterable {
    case menuRequest = "menu_request"
    case eligibleMenuRequest = "eligible_menu_request"
    case sharingControllerHandoffRecovery = "sharing_controller_handoff_recovery"
    case staleActivationRequest = "stale_activation_request"
    case sharingControllerDismissed = "sharing_controller_dismissed"
    case sessionHandoffTimeout = "session_handoff_timeout"
    case hostActivationRejected = "host_activation_rejected"
    case sharePlayUnavailable = "shareplay_unavailable"
    case sharePlayStateArrived = "shareplay_state_arrived"
    case directActivationFailed = "direct_activation_failed"
    case handoffRecoveryFailed = "handoff_recovery_failed"
    case sharingControllerSucceeded = "sharing_controller_succeeded"
    case leaveWithoutSession = "leave_without_session"
}
