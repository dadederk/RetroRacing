import SpriteKit

extension SKSpriteNode {
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
