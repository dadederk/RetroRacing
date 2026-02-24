//
//  InGameHelpView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 19/02/2026.
//

import SwiftUI

/// In-game help modal with controls and audio cue tutorial.
public struct InGameHelpView: View {
    public let controlsDescriptionKey: String
    public let supportsHapticFeedback: Bool
    public let hapticController: HapticFeedbackController?
    public let audioCueTutorialPreviewPlayer: AudioCueTutorialPreviewPlayer
    public let speedWarningFeedbackPreviewPlayer: any SpeedIncreaseWarningFeedbackPlaying

    @Environment(\.dismiss) private var dismiss
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    public init(
        controlsDescriptionKey: String,
        supportsHapticFeedback: Bool,
        hapticController: HapticFeedbackController?,
        audioCueTutorialPreviewPlayer: AudioCueTutorialPreviewPlayer,
        speedWarningFeedbackPreviewPlayer: any SpeedIncreaseWarningFeedbackPlaying
    ) {
        self.controlsDescriptionKey = controlsDescriptionKey
        self.supportsHapticFeedback = supportsHapticFeedback
        self.hapticController = hapticController
        self.audioCueTutorialPreviewPlayer = audioCueTutorialPreviewPlayer
        self.speedWarningFeedbackPreviewPlayer = speedWarningFeedbackPreviewPlayer
    }

    private var sectionHeaderFont: Font {
        (fontPreferenceStore?.font(textStyle: .title3) ?? .title3).weight(.semibold)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if VoiceOverStatus.isVoiceOverRunning {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(GameLocalizedStrings.string("tutorial_section_description"))
                                .font(sectionHeaderFont)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityHeading(.h1)

                            Text(GameLocalizedStrings.string("tutorial_voiceover_intro"))
                                .font(fontPreferenceStore?.font(textStyle: .body) ?? .body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(GameLocalizedStrings.string("settings_controls"))
                            .font(sectionHeaderFont)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h1)

                        ControlsHelpContentView(controlsDescriptionKey: controlsDescriptionKey, showTitle: false)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(GameLocalizedStrings.string("tutorial_audio_title"))
                            .font(sectionHeaderFont)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h1)

                        AudioCueTutorialContentView(
                            previewPlayer: audioCueTutorialPreviewPlayer,
                            speedWarningFeedbackPreviewPlayer: speedWarningFeedbackPreviewPlayer,
                            supportsHapticFeedback: supportsHapticFeedback,
                            hapticController: hapticController
                        )
                    }
                }
                .padding()
            }
            .navigationTitle(GameLocalizedStrings.string("tutorial_help_title"))
            .modifier(InGameHelpNavigationTitleStyle())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(GameLocalizedStrings.string("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#if os(macOS)
private struct InGameHelpNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}
#else
private struct InGameHelpNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationBarTitleDisplayMode(.inline)
    }
}
#endif
