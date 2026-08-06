//
//  SettingsAudioCueTutorialView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 06/08/2026.
//

import SwiftUI

struct SettingsAudioCueTutorialView: View {
    let previewPlayer: AudioCueTutorialPreviewPlayer
    let speedWarningFeedbackPreviewPlayer: any SpeedIncreaseWarningFeedbackPlaying
    let supportsHapticFeedback: Bool
    let hapticController: HapticFeedbackController?
    let presentation: NavigationSurfacePresentation

    @Environment(\.dismiss) private var dismiss
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    var body: some View {
        if presentation == .modal {
            NavigationStack {
                tutorialContent
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(GameLocalizedStrings.string("done")) {
                                dismiss()
                            }
                            .font(primaryFont)
                        }
                    }
            }
        } else {
            tutorialContent
        }
    }

    private var tutorialContent: some View {
        ScrollView {
            AudioCueTutorialContentView(
                previewPlayer: previewPlayer,
                speedWarningFeedbackPreviewPlayer: speedWarningFeedbackPreviewPlayer,
                supportsHapticFeedback: supportsHapticFeedback,
                hapticController: hapticController,
                showAudioCueSections: true
            )
            .padding()
        }
        .navigationTitle(GameLocalizedStrings.string("settings_audio_cue_tutorial"))
        .modifier(SettingsAudioCueTutorialNavigationTitleStyle())
    }

    private var primaryFont: Font {
        fontPreferenceStore?.font(textStyle: .body) ?? .body
    }
}

#if os(iOS)
private struct SettingsAudioCueTutorialNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationBarTitleDisplayMode(.inline)
    }
}
#else
private struct SettingsAudioCueTutorialNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}
#endif
