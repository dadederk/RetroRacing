//
//  RunAchievementTelemetry.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Per-run telemetry used to evaluate control-based achievements on game over.
public struct RunAchievementTelemetry: Codable, Equatable, Sendable {
    public private(set) var usedInputs: Set<AchievementControlInput>
    public private(set) var usedAssistiveTechnologies: Set<AchievementAssistiveTechnology>

    public init(
        usedInputs: Set<AchievementControlInput> = [],
        usedAssistiveTechnologies: Set<AchievementAssistiveTechnology> = []
    ) {
        self.usedInputs = usedInputs
        self.usedAssistiveTechnologies = usedAssistiveTechnologies
    }

    public mutating func record(_ input: AchievementControlInput) {
        usedInputs.insert(input)
    }

    public mutating func recordAssistiveTechnology(_ technology: AchievementAssistiveTechnology) {
        usedAssistiveTechnologies.insert(technology)
    }

    public mutating func reset() {
        usedInputs.removeAll()
        usedAssistiveTechnologies.removeAll()
    }
}
