//
//  CrownInputProcessor.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

public enum CrownInputAction: Equatable, Sendable {
    case none
    case moveLeft
    case moveRight
}

public struct CrownInputProcessor: Sendable {
    public struct Configuration: Sendable {
        public let rotationThreshold: Double

        public init(rotationThreshold: Double) {
            self.rotationThreshold = rotationThreshold
        }

        public static let watchLegacy = Configuration(rotationThreshold: 0.30)
    }

    private let configuration: Configuration
    private var isRotationAllowed = true
    private var accumulatedDelta: Double = 0

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public mutating func handleRotationDelta(_ delta: Double) -> CrownInputAction {
        guard isRotationAllowed else { return .none }
        accumulatedDelta += delta
        guard abs(accumulatedDelta) > configuration.rotationThreshold else { return .none }

        isRotationAllowed = false
        let action: CrownInputAction = accumulatedDelta > 0 ? .moveRight : .moveLeft
        accumulatedDelta = 0
        return action
    }

    public mutating func markIdle() {
        isRotationAllowed = true
        accumulatedDelta = 0
    }
}

@available(*, deprecated, renamed: "CrownInputProcessor")
public typealias LegacyCrownInputProcessor = CrownInputProcessor
