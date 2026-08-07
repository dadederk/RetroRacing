//
//  GameViewControllerInputLifecycleTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 05/08/2026.
//

#if os(iOS)
import SwiftUI
import Testing
import UIKit

@testable import RetroRacingShared

@MainActor
struct GameViewControllerInputLifecycleTests {
    @Test
    func testGivenPreGameMenuWhenGameViewAppearsThenControllerListenerStarts() async throws {
        // Given
        let controllerInputSource = ControllerInputSourceSpy()
        let storeKitService = StoreKitService(userDefaults: makeIsolatedUserDefaults())
        let view = GameView(
            leaderboardService: MockLeaderboardService(),
            ratingService: RatingServiceStub(),
            theme: nil,
            hapticController: nil,
            supportsHapticFeedback: false,
            fontPreferenceStore: nil,
            highestScoreStore: HighestScoreStoreStub(),
            achievementProgressService: AchievementProgressServiceStub(),
            playLimitService: nil,
            style: .universal,
            inputAdapterFactory: TouchInputAdapterFactory(),
            controllerInputSource: controllerInputSource,
            controlsDescriptionKey: "settings_controls_ios",
            shouldStartGame: false,
            isMenuOverlayPresented: .constant(true)
        )
        .environment(storeKitService)
        let hostingController = UIHostingController(rootView: view)
        let windowScene = try #require(
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
        )
        let window = UIWindow(windowScene: windowScene)
        window.frame = windowScene.effectiveGeometry.coordinateSpace.bounds
        window.rootViewController = hostingController

        // When
        window.makeKeyAndVisible()
        hostingController.view.layoutIfNeeded()
        await Task.yield()

        // Then
        #expect(controllerInputSource.startCallCount == 1)

        window.isHidden = true
        window.rootViewController = nil
    }

    private func makeIsolatedUserDefaults() -> UserDefaults {
        let suiteName = "GameViewControllerInputLifecycleTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName) ?? .standard
    }
}

@MainActor
private final class ControllerInputSourceSpy: GameControllerInputSource {
    private(set) var startCallCount = 0

    func start(handler: @escaping @MainActor @Sendable (GameControllerAction) -> Void) {
        startCallCount += 1
    }

    func stop() {}
}

private struct RatingServiceStub: RatingService {
    func requestRating() {}
    func recordBestScoreImprovementAndRequestIfEligible() {}
}

private final class HighestScoreStoreStub: HighestScoreStore {
    func currentBest(for difficulty: GameDifficulty) -> Int { 0 }
    func updateIfHigher(_ score: Int, for difficulty: GameDifficulty) -> Bool { false }
    func syncFromRemote(bestScore: Int, for difficulty: GameDifficulty) {}
}

private final class AchievementProgressServiceStub: AchievementProgressService {
    func performInitialBackfillIfNeeded() {}

    func recordCompletedRun(_ run: CompletedRunAchievementData) -> AchievementProgressUpdate {
        AchievementProgressUpdate(snapshot: .empty, newlyAchievedAchievementIDs: [])
    }

    func replayAchievedAchievements() {}
    func currentProgress() -> AchievementProgressSnapshot { .empty }
}
#endif
