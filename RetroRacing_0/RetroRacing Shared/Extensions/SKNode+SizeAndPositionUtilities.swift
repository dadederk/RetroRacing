import SpriteKit

extension SKSpriteNode {
    func aspectFitToSize(_ size: CGSize) {
        guard let texture = texture else { return }
        
        let verticalRatio = size.height / texture.size().height
        let horizontalRatio = size.width / texture.size().width
        let scaleRatio = horizontalRatio < verticalRatio ? horizontalRatio : verticalRatio
        
        self.size = texture.size()
        setScale(scaleRatio)
    }
}
