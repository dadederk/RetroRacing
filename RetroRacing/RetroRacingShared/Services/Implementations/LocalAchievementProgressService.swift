//
//  LocalAchievementProgressService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Achievement progress coordinator that persists progress locally and reports to Game Center.
public final class LocalAchievementProgressService: AchievementProgressService {
    private enum Backfill {
        static let currentVersion = 1
    }

    private let store: AchievementProgressStore
    private let highestScoreStore: HighestScoreStore
    private let reporter: AchievementProgressReporter

    public init(
        store: AchievementProgressStore,
        highestScoreStore: HighestScoreStore,
        reporter: AchievementProgressReporter
    ) {
        self.store = store
        self.highestScoreStore = highestScoreStore
        self.reporter = reporter
    }

    public func performInitialBackfillIfNeeded() {
        var snapshot = store.load()
        guard snapshot.backfillVersion != Backfill.currentVersion else {
            AppLog.info(
                AppLog.achievement + AppLog.game,
                "ACHIEVEMENT_BACKFILL",
                outcome: .skipped,
                fields: [.reason("already_applied"), .int("version", Backfill.currentVersion)]
            )
            return
        }

        let previousAchievements = snapshot.achievedAchievementIDs
        let cruiseBest = highestScoreStore.currentBest(for: .cruise)
        let fastBest = highestScoreStore.currentBest(for: .fast)
        let rapidBest = highestScoreStore.currentBest(for: .rapid)
        let maxBest = max(cruiseBest, max(fastBest, rapidBest))
        let sumBest = cruiseBest + fastBest + rapidBest

        snapshot.bestRunOvertakes = max(snapshot.bestRunOvertakes, maxBest)
        snapshot.cumulativeOvertakes = max(snapshot.cumulativeOvertakes, sumBest)
        snapshot.achievedAchievementIDs.formUnion(AchievementCatalog.achievedAchievements(for: snapshot))
        snapshot.backfillVersion = Backfill.currentVersion
        store.save(snapshot)

        let newlyAchieved = snapshot.achievedAchievementIDs.subtracting(previousAchievements)
        reporter.reportAchievedAchievements(newlyAchieved)
        AppLog.info(
            AppLog.achievement + AppLog.game,
            "ACHIEVEMENT_BACKFILL",
            outcome: .succeeded,
            fields: [
                .int("version", Backfill.currentVersion),
                .int("maxBest", maxBest),
                .int("sumBest", sumBest),
                .int("newlyAchieved", newlyAchieved.count)
            ]
        )
    }

    @discardableResult
    public func recordCompletedRun(_ run: CompletedRunAchievementData) -> AchievementProgressUpdate {
        var snapshot = store.load()
        let previousAchievements = snapshot.achievedAchievementIDs
        let overtakes = max(0, run.overtakes)
        let hadGAADAssistiveRun = snapshot.gaadAssistiveRunCompleted ?? false
        let isGAADAssistiveRun = !run.activeAssistiveTechnologies.isEmpty
            && AchievementCatalog.isDateInGAADWeek(run.completedAt)

        snapshot.bestRunOvertakes = max(snapshot.bestRunOvertakes, overtakes)
        snapshot.cumulativeOvertakes += overtakes
        snapshot.lifetimeUsedControls.formUnion(run.usedControls)
        snapshot.gaadAssistiveRunCompleted = hadGAADAssistiveRun || isGAADAssistiveRun
        snapshot.achievedAchievementIDs.formUnion(
            AchievementCatalog.achievedAchievementsForRun(runOvertakes: overtakes, snapshot: snapshot)
        )
        store.save(snapshot)

        let newlyAchieved = snapshot.achievedAchievementIDs.subtracting(previousAchievements)
        reporter.reportAchievedAchievements(newlyAchieved)
        AppLog.info(
            AppLog.achievement + AppLog.game,
            "ACHIEVEMENT_RUN_RECORD",
            outcome: .completed,
            fields: [
                .int("overtakes", overtakes),
                .string("controls", serializedControls(run.usedControls)),
                .string("assistive", serializedAssistiveTechnologies(run.activeAssistiveTechnologies)),
                .bool("isGAADAssistiveRun", isGAADAssistiveRun),
                .int("cumulative", snapshot.cumulativeOvertakes),
                .int("bestRun", snapshot.bestRunOvertakes),
                .int("newlyAchieved", newlyAchieved.count)
            ]
        )

        return AchievementProgressUpdate(
            snapshot: snapshot,
            newlyAchievedAchievementIDs: newlyAchieved
        )
    }

    public func currentProgress() -> AchievementProgressSnapshot {
        store.load()
    }

    public func replayAchievedAchievements() {
        let snapshot = store.load()
        guard snapshot.achievedAchievementIDs.isEmpty == false else { return }
        reporter.reportAchievedAchievements(snapshot.achievedAchievementIDs)
        AppLog.info(
            AppLog.achievement + AppLog.game,
            "ACHIEVEMENT_REPLAY",
            outcome: .completed,
            fields: [.int("count", snapshot.achievedAchievementIDs.count)]
        )
    }

    private func serializedControls(_ controls: Set<AchievementControlInput>) -> String {
        controls.map(\.rawValue).sorted().joined(separator: ",")
    }

    private func serializedAssistiveTechnologies(
        _ technologies: Set<AchievementAssistiveTechnology>
    ) -> String {
        technologies.map(\.rawValue).sorted().joined(separator: ",")
    }
}
