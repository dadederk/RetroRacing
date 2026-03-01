//
//  ChallengeCatalog.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Canonical list of local challenge definitions.
public enum ChallengeCatalog {
    public static let definitions: [ChallengeDefinition] = [
        ChallengeDefinition(identifier: .runOvertakes100, requirement: .bestRunOvertakesAtLeast(100)),
        ChallengeDefinition(identifier: .runOvertakes200, requirement: .bestRunOvertakesAtLeast(200)),
        ChallengeDefinition(identifier: .runOvertakes500, requirement: .bestRunOvertakesAtLeast(500)),
        ChallengeDefinition(identifier: .runOvertakes600, requirement: .bestRunOvertakesAtLeast(600)),
        ChallengeDefinition(identifier: .runOvertakes700, requirement: .bestRunOvertakesAtLeast(700)),
        ChallengeDefinition(identifier: .runOvertakes800, requirement: .bestRunOvertakesAtLeast(800)),

        ChallengeDefinition(identifier: .totalOvertakes1k, requirement: .cumulativeOvertakesAtLeast(1_000)),
        ChallengeDefinition(identifier: .totalOvertakes5k, requirement: .cumulativeOvertakesAtLeast(5_000)),
        ChallengeDefinition(identifier: .totalOvertakes10k, requirement: .cumulativeOvertakesAtLeast(10_000)),
        ChallengeDefinition(identifier: .totalOvertakes20k, requirement: .cumulativeOvertakesAtLeast(20_000)),
        ChallengeDefinition(identifier: .totalOvertakes50k, requirement: .cumulativeOvertakesAtLeast(50_000)),
        ChallengeDefinition(identifier: .totalOvertakes100k, requirement: .cumulativeOvertakesAtLeast(100_000)),
        ChallengeDefinition(identifier: .totalOvertakes200k, requirement: .cumulativeOvertakesAtLeast(200_000)),

        ChallengeDefinition(identifier: .controlTap, requirement: .lifetimeControlUsed(.tap)),
        ChallengeDefinition(identifier: .controlSwipe, requirement: .lifetimeControlUsed(.swipe)),
        ChallengeDefinition(identifier: .controlKeyboard, requirement: .lifetimeControlUsed(.keyboard)),
        ChallengeDefinition(identifier: .controlVoiceOver, requirement: .lifetimeControlUsed(.voiceOver)),
        ChallengeDefinition(identifier: .controlDigitalCrown, requirement: .lifetimeControlUsed(.digitalCrown))
    ]

    public static func achievedChallenges(for snapshot: ChallengeProgressSnapshot) -> Set<ChallengeIdentifier> {
        var achieved = Set<ChallengeIdentifier>()

        for definition in definitions where isSatisfied(definition.requirement, by: snapshot) {
            achieved.insert(definition.identifier)
        }

        return achieved
    }

    private static func isSatisfied(
        _ requirement: ChallengeRequirement,
        by snapshot: ChallengeProgressSnapshot
    ) -> Bool {
        switch requirement {
        case .bestRunOvertakesAtLeast(let threshold):
            return snapshot.bestRunOvertakes >= threshold
        case .cumulativeOvertakesAtLeast(let threshold):
            return snapshot.cumulativeOvertakes >= threshold
        case .lifetimeControlUsed(let input):
            return snapshot.lifetimeUsedControls.contains(input)
        }
    }
}
