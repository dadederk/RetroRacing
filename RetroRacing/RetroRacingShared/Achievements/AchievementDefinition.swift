//
//  AchievementDefinition.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

public enum AchievementAssistiveTechnology: String, CaseIterable, Codable, Sendable {
    case voiceOver
    case switchControl
}

public enum AchievementRequirement: Equatable, Sendable {
    case bestRunOvertakesAtLeast(Int)
    case cumulativeOvertakesAtLeast(Int)
    case lifetimeControlUsed(AchievementControlInput)
    case gaadAssistiveRunCompleted
}

public struct AchievementDefinition: Equatable, Sendable {
    public let identifier: AchievementIdentifier
    public let requirement: AchievementRequirement

    public init(identifier: AchievementIdentifier, requirement: AchievementRequirement) {
        self.identifier = identifier
        self.requirement = requirement
    }
}
