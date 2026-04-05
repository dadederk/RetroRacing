//
//  GAADChallengeDebugPanel.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/04/2026.
//

import SwiftUI

public enum GAADChallengeQualificationMode: Sendable {
    case voiceOverAndSwitchControl
    case voiceOverOnly

    var localizedNameKey: String {
        switch self {
        case .voiceOverAndSwitchControl:
            return "debug_gaad_qualification_mode_voiceover_switch"
        case .voiceOverOnly:
            return "debug_gaad_qualification_mode_voiceover_only"
        }
    }
}

/// Debug-only QA panel for validating GAAD challenge eligibility behavior.
@MainActor
public struct GAADChallengeDebugPanel: View {
    private let challengeProgressService: ChallengeProgressService
    private let qualificationMode: GAADChallengeQualificationMode
    private let primaryFont: Font
    private let secondaryFont: Font

    public init(
        challengeProgressService: ChallengeProgressService,
        qualificationMode: GAADChallengeQualificationMode,
        primaryFont: Font,
        secondaryFont: Font
    ) {
        self.challengeProgressService = challengeProgressService
        self.qualificationMode = qualificationMode
        self.primaryFont = primaryFont
        self.secondaryFont = secondaryFont
    }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let snapshot = debugSnapshot(at: context.date)
            VStack(alignment: .leading, spacing: 8) {
                row(
                    labelKey: "debug_gaad_current_time",
                    value: formattedDateTime(snapshot.now)
                )
                row(
                    labelKey: "debug_gaad_window",
                    value: formattedGAADWindow(snapshot.window)
                )
                row(
                    labelKey: "debug_gaad_in_window",
                    value: localizedBoolean(snapshot.isInGAADWeek)
                )
                row(
                    labelKey: "debug_gaad_qualification_mode",
                    value: GameLocalizedStrings.string(qualificationMode.localizedNameKey)
                )
                row(
                    labelKey: "debug_gaad_active_assistive",
                    value: assistiveTechnologiesValue(snapshot.activeAssistiveTechnologies)
                )
                row(
                    labelKey: "debug_gaad_qualifies_now",
                    value: localizedBoolean(snapshot.qualifiesIfCompletedNow)
                )
                row(
                    labelKey: "debug_gaad_signal_latched",
                    value: localizedBoolean(snapshot.gaadCompletionSignalLatched)
                )
                row(
                    labelKey: "debug_gaad_local_achievement",
                    value: localizedBoolean(snapshot.gaadAchievementAchieved)
                )
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func row(labelKey: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(GameLocalizedStrings.string(labelKey))
                .font(secondaryFont)
                .foregroundStyle(.secondary)
            Text(value)
                .font(primaryFont)
        }
    }

    private func debugSnapshot(at now: Date) -> GAADChallengeDebugSnapshot {
        let calendar = Calendar.autoupdatingCurrent
        let year = calendar.component(.year, from: now)
        let window = ChallengeCatalog.gaadWeekDateInterval(forYear: year, calendar: calendar)
        let isInGAADWeek = ChallengeCatalog.isDateInGAADWeek(now, calendar: calendar)
        let activeAssistiveTechnologies = filteredAssistiveTechnologies(
            AssistiveTechnologyStatus.activeTechnologies
        )
        let qualifiesIfCompletedNow = isInGAADWeek && activeAssistiveTechnologies.isEmpty == false
        let progress = challengeProgressService.currentProgress()
        let gaadCompletionSignalLatched = progress.gaadAssistiveRunCompleted ?? false
        let gaadAchievementAchieved = progress.achievedChallengeIDs.contains(.eventGAADAssistive)

        return GAADChallengeDebugSnapshot(
            now: now,
            window: window,
            isInGAADWeek: isInGAADWeek,
            activeAssistiveTechnologies: activeAssistiveTechnologies,
            qualifiesIfCompletedNow: qualifiesIfCompletedNow,
            gaadCompletionSignalLatched: gaadCompletionSignalLatched,
            gaadAchievementAchieved: gaadAchievementAchieved
        )
    }

    private func filteredAssistiveTechnologies(
        _ technologies: Set<ChallengeAssistiveTechnology>
    ) -> Set<ChallengeAssistiveTechnology> {
        switch qualificationMode {
        case .voiceOverAndSwitchControl:
            return technologies
        case .voiceOverOnly:
            return technologies.intersection([.voiceOver])
        }
    }

    private func formattedDateTime(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .standard)
    }

    private func formattedGAADWindow(_ interval: DateInterval?) -> String {
        guard let interval else {
            return GameLocalizedStrings.string("debug_gaad_window_unavailable")
        }
        let calendar = Calendar.autoupdatingCurrent
        let endInclusive = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
        return "\(formattedDateTime(interval.start)) - \(formattedDateTime(endInclusive))"
    }

    private func assistiveTechnologiesValue(_ technologies: Set<ChallengeAssistiveTechnology>) -> String {
        guard technologies.isEmpty == false else {
            return GameLocalizedStrings.string("debug_gaad_assistive_none")
        }
        let labels = technologies
            .map { technology in
                switch technology {
                case .voiceOver:
                    return GameLocalizedStrings.string("debug_gaad_assistive_voiceover")
                case .switchControl:
                    return GameLocalizedStrings.string("debug_gaad_assistive_switch_control")
                }
            }
            .sorted()
        return labels.joined(separator: ", ")
    }

    private func localizedBoolean(_ value: Bool) -> String {
        GameLocalizedStrings.string(value ? "debug_boolean_true" : "debug_boolean_false")
    }
}

private struct GAADChallengeDebugSnapshot: Sendable {
    let now: Date
    let window: DateInterval?
    let isInGAADWeek: Bool
    let activeAssistiveTechnologies: Set<ChallengeAssistiveTechnology>
    let qualifiesIfCompletedNow: Bool
    let gaadCompletionSignalLatched: Bool
    let gaadAchievementAchieved: Bool
}
