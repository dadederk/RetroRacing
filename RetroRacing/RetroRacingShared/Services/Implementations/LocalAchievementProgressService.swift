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
            AppLog.info(AppLog.game + AppLog.achievement, "🏅 Achievement backfill already applied (v\(Backfill.currentVersion))")
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
            AppLog.game + AppLog.achievement,
            "🏅 Achievement backfill applied (v\(Backfill.currentVersion)) maxBest=\(maxBest) sumBest=\(sumBest) newlyAchieved=\(newlyAchieved.count)"
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
        snapshot.achievedAchievementIDs.formUnion(AchievementCatalog.achievedAchievements(for: snapshot))
        store.save(snapshot)

        let newlyAchieved = snapshot.achievedAchievementIDs.subtracting(previousAchievements)
        reporter.reportAchievedAchievements(newlyAchieved)
        AppLog.info(
            AppLog.game + AppLog.achievement,
            """
            🏅 Recorded completed run overtakes=\(overtakes), controls=\(serializedControls(run.usedControls)), \
            assistive=\(serializedAssistiveTechnologies(run.activeAssistiveTechnologies)), \
            gaadAssistiveRun=\(isGAADAssistiveRun), cumulative=\(snapshot.cumulativeOvertakes), \
            bestRun=\(snapshot.bestRunOvertakes), newlyAchieved=\(newlyAchieved.count)
            """
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
            AppLog.game + AppLog.achievement,
            "🏅 Replayed achieved achievements count=\(snapshot.achievedAchievementIDs.count)"
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
