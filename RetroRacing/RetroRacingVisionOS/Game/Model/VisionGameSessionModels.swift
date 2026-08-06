//
//  VisionGameSessionModels.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import RetroRacingShared

enum VisionGameScreen: Equatable {
    case menu
    case playing
    case gameOver
}

enum VisionGamePresentation: Equatable, Sendable {
    case classic
    case tabletop
}

enum VisionPresentationTransition: Equatable {
    case idle
    case moving(VisionPresentationRequest)
}

enum VisionTransitionFailure: String, Error, Equatable, Identifiable {
    case timedOut
    case routingFailed
    case modelUnavailable

    var id: String { rawValue }

    var message: String {
        switch self {
        case .timedOut:
            GameLocalizedStrings.string("vision_transition_timeout")
        case .routingFailed:
            GameLocalizedStrings.string("vision_transition_routing_failed")
        case .modelUnavailable:
            GameLocalizedStrings.string("vision_model_unavailable")
        }
    }
}
