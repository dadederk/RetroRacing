import Foundation

@MainActor
public struct SettingsPreviewDependencies {
    public let audioCueTutorialPreviewPlayer: AudioCueTutorialPreviewPlayer
    public let speedWarningFeedbackPreviewPlayer: any SpeedIncreaseWarningFeedbackPlaying

    public init(
        audioCueTutorialPreviewPlayer: AudioCueTutorialPreviewPlayer,
        speedWarningFeedbackPreviewPlayer: any SpeedIncreaseWarningFeedbackPlaying
    ) {
        self.audioCueTutorialPreviewPlayer = audioCueTutorialPreviewPlayer
        self.speedWarningFeedbackPreviewPlayer = speedWarningFeedbackPreviewPlayer
    }
}

@MainActor
public struct SettingsPreviewDependencyFactory {
    private let laneCuePlayerFactory: @MainActor @Sendable () -> LaneCuePlayer
    private let announcementPoster: any AccessibilityAnnouncementPosting
    private let announcementTextProvider: @MainActor @Sendable () -> String
    private let volumeProvider: @MainActor @Sendable () -> Double

    public init(
        laneCuePlayerFactory: @escaping @MainActor @Sendable () -> LaneCuePlayer,
        announcementPoster: any AccessibilityAnnouncementPosting,
        announcementTextProvider: @escaping @MainActor @Sendable () -> String,
        volumeProvider: @escaping @MainActor @Sendable () -> Double
    ) {
        self.laneCuePlayerFactory = laneCuePlayerFactory
        self.announcementPoster = announcementPoster
        self.announcementTextProvider = announcementTextProvider
        self.volumeProvider = volumeProvider
    }

    public func make(hapticController: HapticFeedbackController?) -> SettingsPreviewDependencies {
        let tutorialPreviewPlayer = AudioCueTutorialPreviewPlayer(
            laneCuePlayer: laneCuePlayerFactory()
        )
        let speedWarningFeedbackPreviewPlayer = SpeedIncreaseWarningFeedbackPlayer(
            announcementPoster: announcementPoster,
            hapticController: hapticController,
            playWarningSound: {
                tutorialPreviewPlayer.playSpeedWarningSound(volume: volumeProvider())
            },
            announcementTextProvider: announcementTextProvider
        )
        return SettingsPreviewDependencies(
            audioCueTutorialPreviewPlayer: tutorialPreviewPlayer,
            speedWarningFeedbackPreviewPlayer: speedWarningFeedbackPreviewPlayer
        )
    }
}
