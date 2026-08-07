//
//  VisionSpatialActions+SwiftUI.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import SwiftUI

extension VisionSpatialActions {
    init(
        pushWindow: PushWindowAction,
        openWindow: OpenWindowAction,
        dismissWindow: DismissWindowAction
    ) {
        self.init(
            pushVolume: { pushWindow(id: $0) },
            openWindow: { openWindow(id: $0) },
            dismissWindow: { dismissWindow(id: $0) }
        )
    }
}
