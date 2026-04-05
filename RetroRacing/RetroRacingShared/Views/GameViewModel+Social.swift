//
//  GameViewModel+Social.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/04/2026.
//

import Foundation

extension GameViewModel {
    func refreshFriendMilestonesForCurrentRun() async {
        let requestedDifficulty = selectedDifficulty

        guard leaderboardService.isAuthenticated() else {
            if requestedDifficulty == selectedDifficulty {
                clearFriendMilestoneState()
            }
            return
        }

        guard let snapshot = await leaderboardService.fetchFriendLeaderboardSnapshot(for: requestedDifficulty) else {
            if requestedDifficulty == selectedDifficulty {
                clearFriendMilestoneState()
            }
            return
        }

        // Ignore stale async results when the user changes speed while a prior refresh is in flight.
        guard requestedDifficulty == selectedDifficulty else { return }

        friendSnapshot = snapshot
        runBaselineBestScore = snapshot.remoteBestScore ?? highestScoreStore.currentBest(for: requestedDifficulty)
        overtakenFriendPlayerIDs.removeAll()
        pendingFriendOvertakeAnnouncement = nil
        hud.gameOverNextFriendAhead = nil
        hud.gameOverOvertakenFriends = []
        updateFriendProgress(forScore: hud.score)
    }

    func updateFriendProgress(forScore score: Int) {
        guard let snapshot = friendSnapshot else {
            currentUpcomingFriendMilestone = nil
            scene?.setUpcomingFriendMilestones([])
            return
        }

        let relevantEntries = snapshot.friendEntries
        // In-race milestones are based on the current run so friend markers can
        // appear every run when approaching those friend best scores.
        let comparisonScore = score

        let newlyOvertakenFriends = relevantEntries.filter { entry in
            entry.score > runBaselineBestScore
            && entry.score <= score
            && overtakenFriendPlayerIDs.contains(entry.playerID) == false
        }

        for entry in newlyOvertakenFriends {
            overtakenFriendPlayerIDs.insert(entry.playerID)
        }
        if newlyOvertakenFriends.isEmpty == false {
            let announcement = friendOvertakeAnnouncement(for: newlyOvertakenFriends)
            pendingFriendOvertakeAnnouncement = announcement
            postFriendOvertakeAnnouncementIfEnabled(announcement)
        }

        let upcomingEntries = relevantEntries.filter { $0.score > comparisonScore }
        guard upcomingEntries.isEmpty == false else {
            currentUpcomingFriendMilestone = nil
            scene?.setUpcomingFriendMilestones([])
            return
        }

        let nextMilestones = upcomingEntries.prefix(2).map { entry in
            UpcomingFriendMilestone(
                playerID: entry.playerID,
                displayName: entry.displayName,
                targetScore: entry.score,
                avatarPNGData: entry.avatarPNGData
            )
        }
        let nextMilestone = nextMilestones.first
        currentUpcomingFriendMilestone = nextMilestone
        scene?.setUpcomingFriendMilestones(nextMilestones)
    }

    func applyFriendGameOverSummaries(finalScore: Int) {
        guard let snapshot = friendSnapshot else {
            hud.gameOverNextFriendAhead = nil
            hud.gameOverOvertakenFriends = []
            return
        }

        let comparisonScore = max(runBaselineBestScore, finalScore)

        if let nextFriend = snapshot.friendEntries.first(where: { $0.score > comparisonScore }) {
            hud.gameOverNextFriendAhead = GameOverFriendAheadSummary(
                playerID: nextFriend.playerID,
                displayName: nextFriend.displayName,
                score: nextFriend.score,
                avatarPNGData: nextFriend.avatarPNGData
            )
        } else {
            hud.gameOverNextFriendAhead = nil
        }

        let overtakenFriends = snapshot.friendEntries
            .filter { $0.score > runBaselineBestScore && $0.score <= finalScore }
            .map {
                GameOverOvertakenFriendSummary(
                    playerID: $0.playerID,
                    displayName: $0.displayName,
                    score: $0.score,
                    avatarPNGData: $0.avatarPNGData
                )
            }

        hud.gameOverOvertakenFriends = overtakenFriends
    }

    func clearFriendMilestoneState() {
        friendSnapshot = nil
        runBaselineBestScore = highestScoreStore.currentBest(for: selectedDifficulty)
        overtakenFriendPlayerIDs.removeAll()
        pendingFriendOvertakeAnnouncement = nil
        currentUpcomingFriendMilestone = nil
        hud.gameOverNextFriendAhead = nil
        hud.gameOverOvertakenFriends = []
        scene?.setUpcomingFriendMilestones([])
    }

    func consumePendingFriendOvertakeAnnouncement() -> String? {
        let announcement = pendingFriendOvertakeAnnouncement
        pendingFriendOvertakeAnnouncement = nil
        return announcement
    }

    private func friendOvertakeAnnouncement(for entries: [FriendLeaderboardEntry]) -> String {
        if let friendName = entries.first?.displayName, entries.count == 1 {
            return GameLocalizedStrings.format("friend_overtake_announcement %@", friendName)
        }
        return GameLocalizedStrings.format("friend_overtake_announcement_multiple %lld", Int64(entries.count))
    }

    private func postFriendOvertakeAnnouncementIfEnabled(_ announcement: String) {
        let isEnabled = FriendOvertakeVoiceOverAnnouncementPreference.currentSelection(
            from: InfrastructureDefaults.userDefaults
        )
        guard isEnabled, VoiceOverStatus.isVoiceOverRunning else { return }
        AccessibilityAnnouncementPoster().postAnnouncement(announcement, priority: .default)
    }
}
