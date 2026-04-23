//
//  AchievementCatalog.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Canonical list of local achievement definitions.
public enum AchievementCatalog {
    public static let definitions: [AchievementDefinition] = [
        AchievementDefinition(identifier: .runOvertakes100, requirement: .bestRunOvertakesAtLeast(100)),
        AchievementDefinition(identifier: .runOvertakes200, requirement: .bestRunOvertakesAtLeast(200)),
        AchievementDefinition(identifier: .runOvertakes300, requirement: .bestRunOvertakesAtLeast(300)),
        AchievementDefinition(identifier: .runOvertakes400, requirement: .bestRunOvertakesAtLeast(400)),
        AchievementDefinition(identifier: .runOvertakes500, requirement: .bestRunOvertakesAtLeast(500)),
        AchievementDefinition(identifier: .runOvertakes600, requirement: .bestRunOvertakesAtLeast(600)),
        AchievementDefinition(identifier: .runOvertakes700, requirement: .bestRunOvertakesAtLeast(700)),
        AchievementDefinition(identifier: .runOvertakes800, requirement: .bestRunOvertakesAtLeast(800)),

        AchievementDefinition(identifier: .totalOvertakes1k, requirement: .cumulativeOvertakesAtLeast(1_000)),
        AchievementDefinition(identifier: .totalOvertakes5k, requirement: .cumulativeOvertakesAtLeast(5_000)),
        AchievementDefinition(identifier: .totalOvertakes10k, requirement: .cumulativeOvertakesAtLeast(10_000)),
        AchievementDefinition(identifier: .totalOvertakes20k, requirement: .cumulativeOvertakesAtLeast(20_000)),
        AchievementDefinition(identifier: .totalOvertakes50k, requirement: .cumulativeOvertakesAtLeast(50_000)),
        AchievementDefinition(identifier: .totalOvertakes100k, requirement: .cumulativeOvertakesAtLeast(100_000)),
        AchievementDefinition(identifier: .totalOvertakes200k, requirement: .cumulativeOvertakesAtLeast(200_000)),

        AchievementDefinition(identifier: .controlTap, requirement: .lifetimeControlUsed(.tap)),
        AchievementDefinition(identifier: .controlSwipe, requirement: .lifetimeControlUsed(.swipe)),
        AchievementDefinition(identifier: .controlKeyboard, requirement: .lifetimeControlUsed(.keyboard)),
        AchievementDefinition(identifier: .controlVoiceOver, requirement: .lifetimeControlUsed(.voiceOver)),
        AchievementDefinition(identifier: .controlDigitalCrown, requirement: .lifetimeControlUsed(.digitalCrown)),
        AchievementDefinition(identifier: .controlGameController, requirement: .lifetimeControlUsed(.gameController)),

        AchievementDefinition(identifier: .eventGAADAssistive, requirement: .gaadAssistiveRunCompleted)
    ]

    /// Evaluates achievements against the full historical snapshot.
    /// Used by the initial backfill to retroactively award everything the player has earned.
    public static func achievedAchievements(for snapshot: AchievementProgressSnapshot) -> Set<AchievementIdentifier> {
        var achieved = Set<AchievementIdentifier>()

        for definition in definitions where isSatisfied(definition.requirement, by: snapshot) {
            achieved.insert(definition.identifier)
        }

        return achieved
    }

    /// Evaluates achievements that a single completed run can unlock.
    /// Streak thresholds are checked against `runOvertakes` (this run only),
    /// not the stored historical best, so a modest run cannot inherit badges
    /// from an earlier high-score run.
    /// All other requirements (cumulative, control, event) evaluate against the full snapshot.
    public static func achievedAchievementsForRun(
        runOvertakes: Int,
        snapshot: AchievementProgressSnapshot
    ) -> Set<AchievementIdentifier> {
        var achieved = Set<AchievementIdentifier>()

        for definition in definitions where isSatisfiedByRun(definition.requirement, runOvertakes: runOvertakes, snapshot: snapshot) {
            achieved.insert(definition.identifier)
        }

        return achieved
    }

    private static func isSatisfied(
        _ requirement: AchievementRequirement,
        by snapshot: AchievementProgressSnapshot
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

    private static func isSatisfiedByRun(
        _ requirement: AchievementRequirement,
        runOvertakes: Int,
        snapshot: AchievementProgressSnapshot
    ) -> Bool {
        switch requirement {
        case .bestRunOvertakesAtLeast(let threshold):
            return runOvertakes >= threshold
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
    static func isDateInGAADWeek(_ date: Date, calendar: Calendar = gaadReferenceCalendar) -> Bool {
        let year = calendar.component(.year, from: date)
        guard let week = gaadWeekDateInterval(forYear: year, calendar: calendar) else {
            return false
        }
        // Treat GAAD week as [start, end) so Monday 00:00 after the week is excluded.
        return date >= week.start && date < week.end
    }

    static func gaadWeekDateInterval(forYear year: Int, calendar: Calendar = gaadReferenceCalendar) -> DateInterval? {
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

    static func thirdThursdayOfMay(in year: Int, calendar: Calendar = gaadReferenceCalendar) -> Date? {
        guard let mayFirst = calendar.date(from: DateComponents(year: year, month: 5, day: 1)) else {
            return nil
        }
        let firstWeekday = calendar.component(.weekday, from: mayFirst)
        let thursdayWeekday = 5 // Sunday = 1, Thursday = 5
        let offsetToFirstThursday = (thursdayWeekday - firstWeekday + 7) % 7
        let thirdThursdayDay = 1 + offsetToFirstThursday + 14
        return calendar.date(from: DateComponents(year: year, month: 5, day: thirdThursdayDay))
    }

    /// Canonical calendar for GAAD calculations: Gregorian dates interpreted in
    /// the user's current local time zone.
    static var gaadReferenceCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }
}
