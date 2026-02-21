//
//  AudioCueTutorialContentView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 19/02/2026.
//

import SwiftUI

/// Safe-lane combinations shown as individual preview buttons in the audio feedback mode section.
private let safeLanePreviewCombinations: [(columns: Set<CueColumn>, labelKey: String)] = [
    ([.left], "tutorial_audio_lane_left"),
    ([.middle], "tutorial_audio_lane_center"),
    ([.right], "tutorial_audio_lane_right"),
    ([.left, .middle], "tutorial_audio_lane_left_center"),
    ([.left, .right], "tutorial_audio_lane_left_right"),
    ([.middle, .right], "tutorial_audio_lane_center_right")
]

/// Lane + safety combinations ordered: safe row first, unsafe row second.
private let laneAndSafetyCombinations: [(column: CueColumn, isSafe: Bool, safetyKey: String)] = [
    (.left, true, "tutorial_audio_preview_safe"),
    (.middle, true, "tutorial_audio_preview_safe"),
    (.right, true, "tutorial_audio_preview_safe"),
    (.left, false, "tutorial_audio_preview_unsafe"),
    (.middle, false, "tutorial_audio_preview_unsafe"),
    (.right, false, "tutorial_audio_preview_unsafe")
]

@MainActor
final class AudioCueTutorialPreviewPlayer {
    private let laneCuePlayer: LaneCuePlayer

    init(laneCuePlayer: LaneCuePlayer = PlatformFactories.makeLaneCuePlayer()) {
        self.laneCuePlayer = laneCuePlayer
    }

    func setVolume(_ volume: Double) {
        laneCuePlayer.setVolume(volume)
    }

    func playLaneModePreview(_ mode: AudioFeedbackMode, safeColumns: Set<CueColumn>) {
        guard mode != .retro else { return }
        laneCuePlayer.playTickCue(safeColumns: safeColumns, mode: mode)
    }

    func playMoveStylePreview(column: CueColumn, isSafe: Bool, style: LaneMoveCueStyle) {
        laneCuePlayer.playMoveCue(
            column: column,
            isSafe: isSafe,
            mode: .cueArpeggio,
            style: style
        )
    }

    func stopAll() {
        laneCuePlayer.stopAll(fadeDuration: 0.1)
    }
}

/// Interactive tutorial for lane cue modes and move cue styles.
public struct AudioCueTutorialContentView: View {
    @AppStorage(SoundPreferences.volumeKey) private var sfxVolume: Double = SoundPreferences.defaultVolume
    @State private var previewPlayer = AudioCueTutorialPreviewPlayer()
    @State private var selectedAudioFeedbackMode: AudioFeedbackMode = .cueLanePulses
    @State private var selectedLaneMoveCueStyle: LaneMoveCueStyle = .laneConfirmation
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init() {}

    /// Three columns at default sizes, one at accessibility sizes to prevent overflow.
    private var gridColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 3
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    private var bodyFont: Font {
        fontPreferenceStore?.font(textStyle: .body) ?? .body
    }

    private var captionFont: Font {
        fontPreferenceStore?.font(textStyle: .caption) ?? .caption
    }

    /// Level-2 heading: smaller than InGameHelpView's title3 section headers.
    private var sectionHeaderFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            audioFeedbackModeSection
            laneChangeCueSection
        }
        .onAppear {
            previewPlayer.setVolume(sfxVolume)
            loadCurrentPreferences()
        }
        .onChange(of: sfxVolume) { _, newValue in
            previewPlayer.setVolume(newValue)
        }
        .onDisappear {
            previewPlayer.stopAll()
        }
    }

    private func loadCurrentPreferences() {
        let savedMode = AudioFeedbackMode.currentSelection(from: InfrastructureDefaults.userDefaults)
        selectedAudioFeedbackMode = savedMode == .retro ? .cueLanePulses : savedMode
        selectedLaneMoveCueStyle = LaneMoveCueStyle.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    // MARK: - Audio feedback mode

    private var audioFeedbackModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(GameLocalizedStrings.string("tutorial_section_audio_feedback_mode"))
                .font(sectionHeaderFont)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            Picker(GameLocalizedStrings.string("tutorial_section_audio_feedback_mode"), selection: $selectedAudioFeedbackMode) {
                ForEach(AudioFeedbackMode.displayOrder.filter { $0 != .retro }, id: \.self) { mode in
                    Text(GameLocalizedStrings.string(mode.localizedNameKey)).tag(mode)
                }
            }
            #if os(watchOS)
            .pickerStyle(.inline)
            #else
            .pickerStyle(.menu)
            .labelsHidden()
            #endif

            Text(GameLocalizedStrings.string(descriptionKey(for: selectedAudioFeedbackMode)))
                .font(captionFont)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(Array(safeLanePreviewCombinations.enumerated()), id: \.offset) { _, combo in
                    playButton(label: GameLocalizedStrings.string(combo.labelKey)) {
                        previewPlayer.playLaneModePreview(selectedAudioFeedbackMode, safeColumns: combo.columns)
                    }
                }
            }

            playButton(label: GameLocalizedStrings.string("tutorial_audio_lane_all")) {
                previewPlayer.playLaneModePreview(selectedAudioFeedbackMode, safeColumns: [.left, .middle, .right])
            }

            Button(GameLocalizedStrings.format("tutorial_set %@", GameLocalizedStrings.string(selectedAudioFeedbackMode.localizedNameKey))) {
                saveAudioFeedbackMode(selectedAudioFeedbackMode)
            }
            .font(captionFont)
            .buttonStyle(.glassProminent)
        }
    }

    private func saveAudioFeedbackMode(_ mode: AudioFeedbackMode) {
        var conditional = ConditionalDefault<AudioFeedbackMode>.load(
            from: InfrastructureDefaults.userDefaults,
            key: AudioFeedbackMode.conditionalDefaultStorageKey
        )
        conditional.setUserOverride(mode)
        conditional.save(to: InfrastructureDefaults.userDefaults, key: AudioFeedbackMode.conditionalDefaultStorageKey)
    }

    // MARK: - Lane change cue

    private var laneChangeCueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(GameLocalizedStrings.string("tutorial_section_lane_change_cue"))
                .font(sectionHeaderFont)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)

            Picker(GameLocalizedStrings.string("tutorial_section_lane_change_cue"), selection: $selectedLaneMoveCueStyle) {
                ForEach(LaneMoveCueStyle.allCases, id: \.self) { style in
                    Text(GameLocalizedStrings.string(style.localizedNameKey)).tag(style)
                }
            }
            #if os(watchOS)
            .pickerStyle(.inline)
            #else
            .pickerStyle(.menu)
            .labelsHidden()
            #endif

            Text(GameLocalizedStrings.string(descriptionKey(for: selectedLaneMoveCueStyle)))
                .font(captionFont)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            laneChangeCueButtons(for: selectedLaneMoveCueStyle)

            Button(GameLocalizedStrings.format("tutorial_set %@", GameLocalizedStrings.string(selectedLaneMoveCueStyle.localizedNameKey))) {
                InfrastructureDefaults.userDefaults.set(
                    selectedLaneMoveCueStyle.rawValue,
                    forKey: LaneMoveCueStyle.storageKey
                )
            }
            .font(captionFont)
            .buttonStyle(.glassProminent)
        }
    }

    @ViewBuilder
    private func laneChangeCueButtons(for style: LaneMoveCueStyle) -> some View {
        switch style {
        case .laneConfirmation:
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach([CueColumn.left, .middle, .right], id: \.rawValue) { column in
                    playButton(label: GameLocalizedStrings.string(laneLabelKey(column))) {
                        previewPlayer.playMoveStylePreview(column: column, isSafe: true, style: style)
                    }
                }
            }
        case .safetyOnly:
            LazyVGrid(columns: gridColumns, spacing: 8) {
                playButton(label: GameLocalizedStrings.string("tutorial_audio_preview_safe")) {
                    previewPlayer.playMoveStylePreview(column: .middle, isSafe: true, style: style)
                }
                playButton(label: GameLocalizedStrings.string("tutorial_audio_preview_unsafe")) {
                    previewPlayer.playMoveStylePreview(column: .middle, isSafe: false, style: style)
                }
            }
        case .laneConfirmationAndSafety:
            // Uses a flat pre-defined array to avoid duplicate IDs from two separate ForEach loops.
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(Array(laneAndSafetyCombinations.enumerated()), id: \.offset) { _, combo in
                    let laneLabel = GameLocalizedStrings.string(laneLabelKey(combo.column))
                    let safetyLabel = GameLocalizedStrings.string(combo.safetyKey)
                    playButton(label: "\(laneLabel) + \(safetyLabel)") {
                        previewPlayer.playMoveStylePreview(column: combo.column, isSafe: combo.isSafe, style: style)
                    }
                }
            }
        }
    }

    private func playButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: "play.fill")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(bodyFont)
        .buttonStyle(.glass)
        .accessibilityLabel(label)
        .accessibilityAddTraits([.playsSound, .startsMediaSession])
    }

    private func laneLabelKey(_ column: CueColumn) -> String {
        switch column {
        case .left: return "tutorial_audio_lane_left"
        case .middle: return "tutorial_audio_lane_center"
        case .right: return "tutorial_audio_lane_right"
        }
    }

    private func descriptionKey(for mode: AudioFeedbackMode) -> String {
        switch mode {
        case .retro, .cueArpeggio:
            return "tutorial_audio_mode_description_arpeggio"
        case .cueLanePulses:
            return "tutorial_audio_mode_description_lane_pulses"
        case .cueChord:
            return "tutorial_audio_mode_description_chord"
        }
    }

    private func descriptionKey(for style: LaneMoveCueStyle) -> String {
        switch style {
        case .laneConfirmation:
            return "tutorial_audio_move_style_description_lane_confirmation"
        case .safetyOnly:
            return "tutorial_audio_move_style_description_safety_only"
        case .laneConfirmationAndSafety:
            return "tutorial_audio_move_style_description_lane_and_safety"
        }
    }
}
