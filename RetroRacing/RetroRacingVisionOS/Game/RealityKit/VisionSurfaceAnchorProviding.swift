//
//  VisionSurfaceAnchorProviding.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import RealityKit

@MainActor
protocol VisionSurfaceAnchorProviding: AnyObject {
    func makeHorizontalSurfaceAnchor(minimumBounds: SIMD2<Float>) -> AnchorEntity
}

@MainActor
final class VisionSurfaceAnchorProvider: VisionSurfaceAnchorProviding {
    func makeHorizontalSurfaceAnchor(minimumBounds: SIMD2<Float>) -> AnchorEntity {
        AnchorEntity(
            .plane(
                .horizontal,
                classification: .any,
                minimumBounds: minimumBounds
            )
        )
    }
}
