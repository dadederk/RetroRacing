//
//  VisionGameInteractionPolicy.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import CoreGraphics

enum VisionDirectTouchSurface: CaseIterable, Equatable, Sendable {
    case classicBoard
    case tabletopRoad
    case hud
    case ornament
    case controls

    var supportsDirectTouch: Bool {
        switch self {
        case .classicBoard, .tabletopRoad:
            true
        case .hud, .ornament, .controls:
            false
        }
    }
}

enum VisionGameInteractionPolicy {
    static func isDirectTouchEnabled(
        on surface: VisionDirectTouchSurface,
        userEnabled: Bool
    ) -> Bool {
        userEnabled && surface.supportsDirectTouch
    }

    static func lane(
        at horizontalLocation: CGFloat,
        width: CGFloat,
        laneCount: Int
    ) -> Int? {
        guard width > 0, laneCount > 0 else { return nil }
        let normalizedLocation = min(max(horizontalLocation / width, 0), 0.999_999)
        return Int(normalizedLocation * CGFloat(laneCount))
    }
}
