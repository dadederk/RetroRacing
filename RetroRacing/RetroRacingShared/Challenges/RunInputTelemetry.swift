//
//  RunInputTelemetry.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Per-run telemetry used to evaluate control-based challenges on game over.
public struct RunInputTelemetry: Codable, Equatable, Sendable {
    public private(set) var usedInputs: Set<ChallengeControlInput>

    public init(usedInputs: Set<ChallengeControlInput> = []) {
        self.usedInputs = usedInputs
    }

    public mutating func record(_ input: ChallengeControlInput) {
        usedInputs.insert(input)
    }

    public mutating func reset() {
        usedInputs.removeAll()
    }
}
