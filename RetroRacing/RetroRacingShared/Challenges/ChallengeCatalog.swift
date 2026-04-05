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
        ChallengeDefinition(identifier: .controlDigitalCrown, requirement: .lifetimeControlUsed(.digitalCrown)),
        ChallengeDefinition(identifier: .controlGameController, requirement: .lifetimeControlUsed(.gameController)),

        ChallengeDefinition(identifier: .eventGAADAssistive, requirement: .gaadAssistiveRunCompleted)
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
        case .gaadAssistiveRunCompleted:
            return snapshot.gaadAssistiveRunCompleted ?? false
        }
    }

    /// Returns `true` when `date` falls in the Monday-Sunday week containing GAAD for that year.
    /// GAAD is defined as the third Thursday of May.
    static func isDateInGAADWeek(_ date: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        let year = calendar.component(.year, from: date)
        guard let week = gaadWeekDateInterval(forYear: year, calendar: calendar) else {
            return false
        }
        // Treat GAAD week as [start, end) so Monday 00:00 after the week is excluded.
        return date >= week.start && date < week.end
    }

    static func gaadWeekDateInterval(forYear year: Int, calendar: Calendar = .autoupdatingCurrent) -> DateInterval? {
        guard let gaadDate = thirdThursdayOfMay(in: year, calendar: calendar) else {
            return nil
        }
        let gaadStartOfDay = calendar.startOfDay(for: gaadDate)
        let weekday = calendar.component(.weekday, from: gaadStartOfDay)
        let mondayWeekday = 2 // Sunday = 1, Monday = 2
        let daysFromMonday = (weekday - mondayWeekday + 7) % 7
        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: gaadStartOfDay),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return nil
        }
        return DateInterval(start: weekStart, end: weekEnd)
    }

    static func thirdThursdayOfMay(in year: Int, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        guard let mayFirst = calendar.date(from: DateComponents(year: year, month: 5, day: 1)) else {
            return nil
        }
        let firstWeekday = calendar.component(.weekday, from: mayFirst)
        let thursdayWeekday = 5 // Sunday = 1, Thursday = 5
        let offsetToFirstThursday = (thursdayWeekday - firstWeekday + 7) % 7
        let thirdThursdayDay = 1 + offsetToFirstThursday + 14
        return calendar.date(from: DateComponents(year: year, month: 5, day: thirdThursdayDay))
    }
}
