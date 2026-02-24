import Foundation

@MainActor
public protocol SpeedIncreaseWarningFeedbackPlaying {
    func play(mode: SpeedWarningFeedbackMode)
}

/// Shared runtime/preview dispatcher for speed-increase warning feedback.
@MainActor
public struct SpeedIncreaseWarningFeedbackPlayer: SpeedIncreaseWarningFeedbackPlaying {
    private let announcementPoster: any AccessibilityAnnouncementPosting
    private let hapticController: HapticFeedbackController?
    private let playWarningSound: @MainActor @Sendable () -> Void
    private let announcementTextProvider: @MainActor @Sendable () -> String

    public init(
        announcementPoster: any AccessibilityAnnouncementPosting,
        hapticController: HapticFeedbackController?,
        playWarningSound: @escaping @MainActor @Sendable () -> Void,
        announcementTextProvider: @escaping @MainActor @Sendable () -> String
    ) {
        self.announcementPoster = announcementPoster
        self.hapticController = hapticController
        self.playWarningSound = playWarningSound
        self.announcementTextProvider = announcementTextProvider
    }

    public func play(mode: SpeedWarningFeedbackMode) {
        switch mode {
        case .announcement:
            announcementPoster.postAnnouncement(
                announcementTextProvider(),
                priority: .high
            )
        case .warningHaptic:
            hapticController?.triggerWarningHaptic()
            hapticController?.triggerWarningHaptic()
        case .warningSound:
            playWarningSound()
        case .none:
            break
        }
    }
}
