//
//  GameOverView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 16/02/2026.
//

import SwiftUI

/// Shared game-over modal shown across platforms.
public struct GameOverView: View {
    public let score: Int
    public let bestScore: Int
    public let difficulty: GameDifficulty
    public let isNewRecord: Bool
    public let previousBestScore: Int?
    public let nextFriendAhead: GameOverFriendAheadSummary?
    public let overtakenFriends: [GameOverOvertakenFriendSummary]
    public let newlyAchievedAchievementIDs: [AchievementIdentifier]
    public let onRestart: () -> Void
    public let onFinish: () -> Void
    public let onPresented: (() -> Void)?

    @Environment(\.fontPreferenceStore) var fontPreferenceStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) var avatarSize: CGFloat = 24
    @State private var isAchievementModalPresented = false
    #if !os(watchOS) && !os(tvOS)
    // Internal (not private) so GameOverView+Sharing.swift can read and write it across files.
    @State var gameOverShareImageURL: URL?
    #endif

    static let sharedBundle = Bundle(for: GameScene.self)
    #if !os(watchOS) && !os(tvOS)
    static let shareImageFileName = "retroracing-game-over-share.png"

    static var shareToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .automatic
        #else
        .topBarTrailing
        #endif
    }
    #endif

    public init(
        score: Int,
        bestScore: Int,
        difficulty: GameDifficulty,
        isNewRecord: Bool,
        previousBestScore: Int?,
        nextFriendAhead: GameOverFriendAheadSummary? = nil,
        overtakenFriends: [GameOverOvertakenFriendSummary] = [],
        newlyAchievedAchievementIDs: [AchievementIdentifier] = [],
        onRestart: @escaping () -> Void,
        onFinish: @escaping () -> Void,
        onPresented: (() -> Void)? = nil
    ) {
        self.score = score
        self.bestScore = bestScore
        self.difficulty = difficulty
        self.isNewRecord = isNewRecord
        self.previousBestScore = previousBestScore
        self.nextFriendAhead = nextFriendAhead
        self.overtakenFriends = overtakenFriends
        self.newlyAchievedAchievementIDs = newlyAchievedAchievementIDs
        self.onRestart = onRestart
        self.onFinish = onFinish
        self.onPresented = onPresented
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                gameOverMainContent
            }
            #if os(iOS) || os(visionOS)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomActionBar
            }
            .ignoresSafeArea(edges: .bottom)
            #endif
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.background)
            .navigationTitle(GameLocalizedStrings.string("game_over_encouragement_title"))
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #if !os(watchOS) && !os(tvOS)
            .toolbar {
                ToolbarItem(placement: Self.shareToolbarPlacement) {
                    shareToolbarItem
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 640)
        #endif
        .interactiveDismissDisabled(true)
        .sheet(isPresented: $isAchievementModalPresented) {
            AchievementUnlockView(
                achievementIDs: newlyAchievedAchievementIDs,
                onDone: { isAchievementModalPresented = false }
            )
        }
        .onAppear {
            onPresented?()
            isAchievementModalPresented = newlyAchievedAchievementIDs.isEmpty == false
            #if !os(watchOS) && !os(tvOS)
            refreshShareImage()
            #endif
        }
        #if !os(watchOS) && !os(tvOS)
        .onChange(of: colorScheme) { _, _ in
            refreshShareImage()
        }
        #endif
    }
}

#Preview("New Record") {
    GameOverView(
        score: 210,
        bestScore: 210,
        difficulty: .rapid,
        isNewRecord: true,
        previousBestScore: 182,
        nextFriendAhead: GameOverFriendAheadSummary(
            playerID: "friend-2",
            displayName: "Rita",
            score: 240,
            avatarPNGData: nil
        ),
        overtakenFriends: [
            GameOverOvertakenFriendSummary(
                playerID: "friend-1",
                displayName: "Alex",
                score: 200,
                avatarPNGData: nil
            )
        ],
        onRestart: {},
        onFinish: {}
    )
}

#Preview("Finished") {
    GameOverView(
        score: 96,
        bestScore: 210,
        difficulty: .fast,
        isNewRecord: false,
        previousBestScore: nil,
        onRestart: {},
        onFinish: {}
    )
}
