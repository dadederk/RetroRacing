//
//  VisionSpatialActions+SwiftUI.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import SwiftUI

extension VisionSpatialActions {
    init(
        openImmersiveSpace: OpenImmersiveSpaceAction,
        dismissImmersiveSpace: DismissImmersiveSpaceAction,
        openWindow: OpenWindowAction,
        dismissWindow: DismissWindowAction
    ) {
        self.init(
            openImmersiveSpace: { id in
                switch await openImmersiveSpace(id: id) {
                case .opened: .opened
                case .userCancelled: .userCancelled
                case .error: .failed
                @unknown default: .failed
                }
            },
            dismissImmersiveSpace: {
                await dismissImmersiveSpace()
            },
            openWindow: { openWindow(id: $0) },
            dismissWindow: { dismissWindow(id: $0) }
        )
    }
}
