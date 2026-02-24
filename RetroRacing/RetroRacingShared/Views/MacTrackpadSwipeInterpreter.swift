//
//  MacTrackpadSwipeInterpreter.swift
//  RetroRacingShared
//
//  Created by Codex on 24/02/2026.
//

import Foundation
import CoreGraphics

enum MacTrackpadSwipeAction: Equatable {
    case moveLeft
    case moveRight
}

struct MacTrackpadSwipeInterpreter {
    enum Phase {
        case began
        case changed
        case ended
        case cancelled
        case none
    }

    private let horizontalThreshold: CGFloat
    private let phaselessResetInterval: TimeInterval
    private var hasTriggeredInCurrentGesture = false
    private var lastTriggerTimestamp: TimeInterval?

    init(
        horizontalThreshold: CGFloat = 12,
        phaselessResetInterval: TimeInterval = 0.22
    ) {
        self.horizontalThreshold = horizontalThreshold
        self.phaselessResetInterval = phaselessResetInterval
    }

    mutating func interpret(
        deltaX: CGFloat,
        deltaY: CGFloat,
        phase: Phase,
        isDirectionInvertedFromDevice: Bool,
        timestamp: TimeInterval
    ) -> MacTrackpadSwipeAction? {
        if phase == .began {
            hasTriggeredInCurrentGesture = false
        } else if phase == .ended || phase == .cancelled {
            hasTriggeredInCurrentGesture = false
            return nil
        } else if phase == .none,
                  let lastTriggerTimestamp,
                  (timestamp - lastTriggerTimestamp) >= phaselessResetInterval {
            hasTriggeredInCurrentGesture = false
        }

        guard hasTriggeredInCurrentGesture == false else {
            return nil
        }

        let normalizedDeltaX = isDirectionInvertedFromDevice ? -deltaX : deltaX
        let horizontalMagnitude = abs(normalizedDeltaX)
        let verticalMagnitude = abs(deltaY)
        guard horizontalMagnitude >= horizontalThreshold,
              horizontalMagnitude > verticalMagnitude else {
            return nil
        }

        hasTriggeredInCurrentGesture = true
        lastTriggerTimestamp = timestamp
        return normalizedDeltaX < 0 ? .moveLeft : .moveRight
    }
}
