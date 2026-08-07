//
//  VisionSpatialRouting.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import Foundation

enum VisionImmersiveSpaceOpenResult: Equatable, Sendable {
    case opened
    case userCancelled
    case failed
}

enum VisionImmersiveSpaceRoutingError: Error, Equatable {
    case userCancelled
    case failed
}

@MainActor
struct VisionSpatialActions {
    let openImmersiveSpace: (String) async -> VisionImmersiveSpaceOpenResult
    let dismissImmersiveSpace: () async -> Void
    let openWindow: (String) -> Void
    let dismissWindow: (String) -> Void
}

@MainActor
protocol VisionImmersiveSpaceRouting: AnyObject {
    func open(using actions: VisionSpatialActions) async throws
    func dismiss(using actions: VisionSpatialActions) async
}

@MainActor
final class VisionImmersiveSpaceRouter: VisionImmersiveSpaceRouting {
    private let immersiveSpaceID: String

    init(immersiveSpaceID: String) {
        self.immersiveSpaceID = immersiveSpaceID
    }

    func open(using actions: VisionSpatialActions) async throws {
        switch await actions.openImmersiveSpace(immersiveSpaceID) {
        case .opened:
            return
        case .userCancelled:
            throw VisionImmersiveSpaceRoutingError.userCancelled
        case .failed:
            throw VisionImmersiveSpaceRoutingError.failed
        }
    }

    func dismiss(using actions: VisionSpatialActions) async {
        await actions.dismissImmersiveSpace()
    }
}
