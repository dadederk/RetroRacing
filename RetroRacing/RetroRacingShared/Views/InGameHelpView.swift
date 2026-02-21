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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore
    /// Observed to reactively show/hide the audio tutorial when the mode is changed from within it.
    @AppStorage(AudioFeedbackMode.conditionalDefaultStorageKey) private var audioFeedbackModeData: Data = Data()

    public init(controlsDescriptionKey: String) {
        self.controlsDescriptionKey = controlsDescriptionKey
    }

    private var sectionHeaderFont: Font {
        (fontPreferenceStore?.font(textStyle: .title3) ?? .title3).weight(.semibold)
    }

    private var isAudioCueTutorialVisible: Bool {
        AudioFeedbackMode.currentSelection(from: InfrastructureDefaults.userDefaults).supportsAudioCueTutorial
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

                    if isAudioCueTutorialVisible {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(GameLocalizedStrings.string("tutorial_audio_title"))
                                .font(sectionHeaderFont)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityHeading(.h1)

                            AudioCueTutorialContentView()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(GameLocalizedStrings.string("tutorial_help_title"))
            .navigationBarTitleDisplayMode(.inline)
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
