import Foundation

public enum CrownInputAction: Equatable, Sendable {
    case none
    case moveLeft
    case moveRight
}

public struct LegacyCrownInputProcessor: Sendable {
    public struct Configuration: Sendable {
        public let rotationThreshold: Double

        public init(rotationThreshold: Double) {
            self.rotationThreshold = rotationThreshold
        }

        public static let watchLegacy = Configuration(rotationThreshold: 0.05)
    }

    private let configuration: Configuration
    private var isRotationAllowed = true

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public mutating func handleRotationDelta(_ delta: Double) -> CrownInputAction {
        guard isRotationAllowed else { return .none }
        guard abs(delta) > configuration.rotationThreshold else { return .none }

        isRotationAllowed = false
        return delta > 0 ? .moveRight : .moveLeft
    }

    public mutating func markIdle() {
        isRotationAllowed = true
    }
}
