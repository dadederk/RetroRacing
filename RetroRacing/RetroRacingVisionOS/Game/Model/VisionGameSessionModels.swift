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
    case ready
    case active
    case returning
    case failure(VisionSpatialFailure)

    var isTransitioning: Bool {
        switch self {
        case .preflighting, .opening, .returning:
            true
        case .inactive, .ready, .active, .failure:
            false
        }
    }

    var isSpatialContentPresented: Bool {
        switch self {
        case .opening, .ready, .active, .returning:
            true
        case .inactive, .preflighting, .failure:
            false
        }
    }
}

enum VisionSpatialFailure: String, Error, Equatable, Identifiable {
    case modelUnavailable

    var id: String { rawValue }

    var message: String {
        switch self {
        case .modelUnavailable:
            GameLocalizedStrings.string("vision_model_unavailable")
        }
    }
}
