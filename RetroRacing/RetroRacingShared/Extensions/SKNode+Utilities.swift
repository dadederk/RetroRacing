//
//  SKNode+Utilities.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SpriteKit

extension SKSpriteNode {
    /// Scales the sprite to fit inside the given target size while preserving aspect ratio.
    func aspectFitToSize(_ targetSize: CGSize) {
        guard let texture = texture else { return }
        let texSize = texture.size()
        guard texSize.width > 0, texSize.height > 0 else { return }

        let verticalRatio = targetSize.height / texSize.height
        let horizontalRatio = targetSize.width / texSize.width
        let scaleRatio = min(horizontalRatio, verticalRatio)

        self.size = texSize
        setScale(scaleRatio)
    }
}
