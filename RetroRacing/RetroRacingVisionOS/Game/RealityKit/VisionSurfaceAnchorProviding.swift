//
//  VisionSurfaceAnchorProviding.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import RealityKit

@MainActor
struct VisionSurfaceAnchorPlacement {
    let anchor: AnchorEntity
    let contentParent: Entity
}

@MainActor
protocol VisionSurfaceAnchorProviding: AnyObject {
    func makeHorizontalSurfacePlacement(
        minimumBounds: SIMD2<Float>
    ) -> VisionSurfaceAnchorPlacement
}

@MainActor
final class VisionSurfaceAnchorProvider: VisionSurfaceAnchorProviding {
    func makeHorizontalSurfacePlacement(
        minimumBounds: SIMD2<Float>
    ) -> VisionSurfaceAnchorPlacement {
        let anchor = AnchorEntity(
            .plane(
                .horizontal,
                classification: .any,
                minimumBounds: minimumBounds
            )
        )
        return VisionSurfaceAnchorPlacement(
            anchor: anchor,
            contentParent: anchor
        )
    }
}

#if targetEnvironment(simulator) && DEBUG
@MainActor
final class VisionSimulatorSurfaceAnchorProvider: VisionSurfaceAnchorProviding {
    static let contentPosition = SIMD3<Float>(0, -0.4, -0.9)

    func makeHorizontalSurfacePlacement(
        minimumBounds: SIMD2<Float>
    ) -> VisionSurfaceAnchorPlacement {
        let anchor = AnchorEntity(.head)
        anchor.name = "retrorapid-simulator-preview-anchor"

        let contentParent = Entity()
        contentParent.name = "retrorapid-simulator-preview-position"
        contentParent.position = Self.contentPosition
        anchor.addChild(contentParent)

        return VisionSurfaceAnchorPlacement(
            anchor: anchor,
            contentParent: contentParent
        )
    }
}
#endif

@MainActor
enum VisionSurfaceAnchorProviderFactory {
    static func makeForCurrentEnvironment() -> any VisionSurfaceAnchorProviding {
        #if targetEnvironment(simulator) && DEBUG
        VisionSimulatorSurfaceAnchorProvider()
        #else
        VisionSurfaceAnchorProvider()
        #endif
    }
}
