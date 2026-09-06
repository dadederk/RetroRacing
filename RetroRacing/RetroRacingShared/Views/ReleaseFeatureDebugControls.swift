//
//  ReleaseFeatureDebugControls.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 06/09/2026.
//

import SwiftUI

/// Shared rollout controls; platform launch itself remains a distribution decision.
public struct ReleaseFeatureDebugControls: View {
    public let features: any ReleaseFeatureProviding
    public let showsIcons: Bool
    public let isGameSessionInProgress: Bool
    public let onChange: () -> Void

    public init(
        features: any ReleaseFeatureProviding,
        showsIcons: Bool,
        isGameSessionInProgress: Bool,
        onChange: @escaping () -> Void
    ) {
        self.features = features
        self.showsIcons = showsIcons
        self.isGameSessionInProgress = isGameSessionInProgress
        self.onChange = onChange
    }

    public var body: some View {
        if features.allowsOverrides {
            ForEach(visibleFeatures, id: \.self) { feature in
                Picker(selection: Binding(
                    get: { features.override(for: feature) },
                    set: { features.setOverride($0, for: feature); onChange() }
                )) {
                    ForEach(ReleaseFeatureOverride.allCases, id: \.self) { option in
                        Text(GameLocalizedStrings.string(option.titleKey))
                            .appFont(.body)
                            .tag(option)
                    }
                } label: {
                    Text(GameLocalizedStrings.string(feature.titleKey)).appFont(.body)
                }
                .disabled(isGameSessionInProgress)
                .accessibilityIdentifier("release_feature_\(feature.rawValue)")
            }
            Button {
                features.resetOverrides()
                onChange()
            } label: {
                Text(GameLocalizedStrings.string("debug_release_reset")).appFont(.body)
            }
            .disabled(isGameSessionInProgress)
        }
    }

    private var visibleFeatures: [ReleaseFeature] {
        ReleaseFeature.allCases.filter { feature in
            switch feature {
            case .alternateIcons: showsIcons
            case .discTheme: features.platform.showsExperimentalToggle(for: .thirtyTwoBit)
            case .polygonTheme: features.platform.showsExperimentalToggle(for: .sixtyFourBit)
            case .sharePlay: features.platform == .iPhone || features.platform == .iPad || features.platform == .macOS
            case .retroThemes: true
            }
        }
    }
}
