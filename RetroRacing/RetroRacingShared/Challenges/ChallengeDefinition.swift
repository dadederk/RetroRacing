//
//  ChallengeDefinition.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

public enum ChallengeRequirement: Equatable, Sendable {
    case bestRunOvertakesAtLeast(Int)
    case cumulativeOvertakesAtLeast(Int)
    case lifetimeControlUsed(ChallengeControlInput)
}

public struct ChallengeDefinition: Equatable, Sendable {
    public let identifier: ChallengeIdentifier
    public let requirement: ChallengeRequirement

    public init(identifier: ChallengeIdentifier, requirement: ChallengeRequirement) {
        self.identifier = identifier
        self.requirement = requirement
    }
}
