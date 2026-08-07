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
    case spatial
}

struct VisionSpatialTransitionID: Hashable, Sendable {
    let rawValue: UInt64
}

enum VisionSpatialState: Equatable {
    case inactive
    case preflighting
    case opening
    case searchingSurface(showTroubleshooting: Bool)
    case awaitingConfirmation
    case active
    case recoveringSurface(showTroubleshooting: Bool)
    case returning
    case failure(VisionSpatialFailure)

    var isTransitioning: Bool {
        switch self {
        case .preflighting, .opening, .searchingSurface, .recoveringSurface, .returning:
            true
        case .inactive, .awaitingConfirmation, .active, .failure:
            false
        }
    }

    var isSpatialContentPresented: Bool {
        switch self {
        case .opening, .searchingSurface, .awaitingConfirmation, .active,
             .recoveringSurface, .returning:
            true
        case .inactive, .preflighting, .failure:
            false
        }
    }
}

enum VisionSpatialFailure: String, Error, Equatable, Identifiable {
    case modelUnavailable
    case immersiveOpenFailed
    case immersiveOpenCancelled
    case systemDismissed

    var id: String { rawValue }

    var message: String {
        switch self {
        case .modelUnavailable:
            GameLocalizedStrings.string("vision_model_unavailable")
        case .immersiveOpenFailed:
            GameLocalizedStrings.string("vision_immersive_open_failed")
        case .immersiveOpenCancelled:
            GameLocalizedStrings.string("vision_immersive_open_cancelled")
        case .systemDismissed:
            GameLocalizedStrings.string("vision_immersive_system_dismissed")
        }
    }
}
