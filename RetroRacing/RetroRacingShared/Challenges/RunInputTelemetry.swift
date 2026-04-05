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
    public private(set) var usedAssistiveTechnologies: Set<ChallengeAssistiveTechnology>

    public init(
        usedInputs: Set<ChallengeControlInput> = [],
        usedAssistiveTechnologies: Set<ChallengeAssistiveTechnology> = []
    ) {
        self.usedInputs = usedInputs
        self.usedAssistiveTechnologies = usedAssistiveTechnologies
    }

    public mutating func record(_ input: ChallengeControlInput) {
        usedInputs.insert(input)
    }

    public mutating func recordAssistiveTechnology(_ technology: ChallengeAssistiveTechnology) {
        usedAssistiveTechnologies.insert(technology)
    }

    public mutating func reset() {
        usedInputs.removeAll()
        usedAssistiveTechnologies.removeAll()
    }
}
