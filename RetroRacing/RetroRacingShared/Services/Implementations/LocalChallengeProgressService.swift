//
//  LocalChallengeProgressService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Local-only challenge progress coordinator used until ASC achievements are configured.
public final class LocalChallengeProgressService: ChallengeProgressService {
    private enum Backfill {
        static let currentVersion = 1
    }

    private let store: ChallengeProgressStore
    private let highestScoreStore: HighestScoreStore
    private let reporter: ChallengeProgressReporter

    public init(
        store: ChallengeProgressStore,
        highestScoreStore: HighestScoreStore,
        reporter: ChallengeProgressReporter
    ) {
        self.store = store
        self.highestScoreStore = highestScoreStore
        self.reporter = reporter
    }

    public func performInitialBackfillIfNeeded() {
        var snapshot = store.load()
        guard snapshot.backfillVersion != Backfill.currentVersion else {
            AppLog.info(AppLog.game + AppLog.challenge, "🏅 Challenge backfill already applied (v\(Backfill.currentVersion))")
            return
        }

        let previousAchievements = snapshot.achievedChallengeIDs
        let cruiseBest = highestScoreStore.currentBest(for: .cruise)
        let fastBest = highestScoreStore.currentBest(for: .fast)
        let rapidBest = highestScoreStore.currentBest(for: .rapid)
        let maxBest = max(cruiseBest, max(fastBest, rapidBest))
        let sumBest = cruiseBest + fastBest + rapidBest

        snapshot.bestRunOvertakes = max(snapshot.bestRunOvertakes, maxBest)
        snapshot.cumulativeOvertakes = max(snapshot.cumulativeOvertakes, sumBest)
        snapshot.achievedChallengeIDs.formUnion(ChallengeCatalog.achievedChallenges(for: snapshot))
        snapshot.backfillVersion = Backfill.currentVersion
        store.save(snapshot)

        let newlyAchieved = snapshot.achievedChallengeIDs.subtracting(previousAchievements)
        reporter.reportAchievedChallenges(newlyAchieved)
        AppLog.info(
            AppLog.game + AppLog.challenge,
            "🏅 Challenge backfill applied (v\(Backfill.currentVersion)) maxBest=\(maxBest) sumBest=\(sumBest) newlyAchieved=\(newlyAchieved.count)"
        )
    }

    @discardableResult
    public func recordCompletedRun(_ run: CompletedRunChallengeData) -> ChallengeProgressUpdate {
        var snapshot = store.load()
        let previousAchievements = snapshot.achievedChallengeIDs
        let overtakes = max(0, run.overtakes)
        let hadGAADAssistiveRun = snapshot.gaadAssistiveRunCompleted ?? false
        let isGAADAssistiveRun = !run.activeAssistiveTechnologies.isEmpty
            && ChallengeCatalog.isDateInGAADWeek(run.completedAt)

        snapshot.bestRunOvertakes = max(snapshot.bestRunOvertakes, overtakes)
        snapshot.cumulativeOvertakes += overtakes
        snapshot.lifetimeUsedControls.formUnion(run.usedControls)
        snapshot.gaadAssistiveRunCompleted = hadGAADAssistiveRun || isGAADAssistiveRun
        snapshot.achievedChallengeIDs.formUnion(ChallengeCatalog.achievedChallenges(for: snapshot))
        store.save(snapshot)

        let newlyAchieved = snapshot.achievedChallengeIDs.subtracting(previousAchievements)
        reporter.reportAchievedChallenges(newlyAchieved)
        AppLog.info(
            AppLog.game + AppLog.challenge,
            """
            🏅 Recorded completed run overtakes=\(overtakes), controls=\(serializedControls(run.usedControls)), \
            assistive=\(serializedAssistiveTechnologies(run.activeAssistiveTechnologies)), \
            gaadAssistiveRun=\(isGAADAssistiveRun), cumulative=\(snapshot.cumulativeOvertakes), \
            bestRun=\(snapshot.bestRunOvertakes), newlyAchieved=\(newlyAchieved.count)
            """
        )

        return ChallengeProgressUpdate(
            snapshot: snapshot,
            newlyAchievedChallengeIDs: newlyAchieved
        )
    }

    public func currentProgress() -> ChallengeProgressSnapshot {
        store.load()
    }

    public func replayAchievedChallenges() {
        let snapshot = store.load()
        guard snapshot.achievedChallengeIDs.isEmpty == false else { return }
        reporter.reportAchievedChallenges(snapshot.achievedChallengeIDs)
        AppLog.info(
            AppLog.game + AppLog.challenge,
            "🏅 Replayed achieved challenges count=\(snapshot.achievedChallengeIDs.count)"
        )
    }

    private func serializedControls(_ controls: Set<ChallengeControlInput>) -> String {
        controls.map(\.rawValue).sorted().joined(separator: ",")
    }

    private func serializedAssistiveTechnologies(
        _ technologies: Set<ChallengeAssistiveTechnology>
    ) -> String {
        technologies.map(\.rawValue).sorted().joined(separator: ",")
    }
}
