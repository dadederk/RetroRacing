//
//  VisionWindowActions+SwiftUI.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import SwiftUI

extension VisionWindowActions {
    init(
        pushWindow: PushWindowAction,
        openWindow: OpenWindowAction,
        dismissWindow: DismissWindowAction
    ) {
        self.init(
            push: { pushWindow(id: $0) },
            open: {
                await Task.yield()
                openWindow(id: $0)
            },
            dismiss: { dismissWindow(id: $0) }
        )
    }
}
