//
//  VisionSpatialRouting.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import Foundation

@MainActor
struct VisionSpatialActions {
    let pushVolume: (String) -> Void
    let openWindow: (String) -> Void
    let dismissWindow: (String) -> Void
}

@MainActor
protocol VisionVolumeRouting: AnyObject {
    func push(using actions: VisionSpatialActions)
    func hideClassic(using actions: VisionSpatialActions)
    func restoreClassic(using actions: VisionSpatialActions)
    func dismiss(using actions: VisionSpatialActions) async
}

@MainActor
final class VisionVolumeRouter: VisionVolumeRouting {
    private let volumeID: String
    private let classicWindowID: String

    init(volumeID: String, classicWindowID: String) {
        self.volumeID = volumeID
        self.classicWindowID = classicWindowID
    }

    func push(using actions: VisionSpatialActions) {
        actions.pushVolume(volumeID)
    }

    func hideClassic(using actions: VisionSpatialActions) {
        actions.dismissWindow(classicWindowID)
    }

    func restoreClassic(using actions: VisionSpatialActions) {
        actions.openWindow(classicWindowID)
    }

    func dismiss(using actions: VisionSpatialActions) async {
        actions.dismissWindow(volumeID)
    }
}
