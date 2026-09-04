//
//  ThemeGalleryView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/08/2026.
//

import SwiftUI
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Selectable gallery for the installed visual themes.
public struct ThemeGalleryView: View {
    public let themeManager: ThemeManager
    public let playLimitService: PlayLimitService?

    @Environment(StoreKitService.self) private var storeKit
    @State private var isShowingPaywall = false

    public init(
        themeManager: ThemeManager,
        playLimitService: PlayLimitService? = nil
    ) {
        self.themeManager = themeManager
        self.playLimitService = playLimitService
    }

    public var body: some View {
        List {
            ThemeGallerySections(
                previewModels: previewModels,
                selectedThemeID: themeManager.currentTheme.id,
                showsUnlockSection: storeKit.shouldShowFreeTierAffordances,
                hasUnlimitedAccess: storeKit.hasPremiumAccess,
                hasResolvedInitialEntitlements: storeKit.hasResolvedInitialEntitlements,
                isSelectionDisabled: false,
                onUnlockRequest: { isShowingPaywall = true },
                onPreviewSelection: selectTheme
            )
        }
        .navigationTitle(GameLocalizedStrings.string("settings_theme_gallery_title"))
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(playLimitService: playLimitService)
        }
    }

    private var previewModels: [ThemeGalleryPreviewModel] {
        themeManager.availableThemes.map {
            ThemeGalleryPreviewModel(
                theme: $0,
                isIncreaseContrastEnabled: isSystemIncreaseContrastEnabled
            )
        }
    }

    private func selectTheme(for preview: ThemeGalleryPreviewModel) {
        guard let theme = themeManager.availableThemes.first(where: { $0.id == preview.id }) else {
            return
        }

        switch ThemeGallerySelectionPolicy.action(
            previewID: preview.id,
            currentThemeID: themeManager.currentTheme.id,
            isThemePremium: theme.isPremium,
            hasUnlimitedAccess: storeKit.hasPremiumAccess,
            hasResolvedInitialEntitlements: storeKit.hasResolvedInitialEntitlements
        ) {
        case .none:
            return
        case .waitForEntitlement:
            return
        case .selectTheme:
            themeManager.setTheme(theme)
        case .presentPaywall:
            isShowingPaywall = true
        }
    }

    private var isSystemIncreaseContrastEnabled: Bool {
        #if os(iOS) || os(tvOS) || os(visionOS)
        UIAccessibility.isDarkerSystemColorsEnabled
        #elseif os(macOS)
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        #else
        false
        #endif
    }
}

struct ThemeGallerySections: View {
    let previewModels: [ThemeGalleryPreviewModel]
    let selectedThemeID: ThemeID
    let showsUnlockSection: Bool
    let hasUnlimitedAccess: Bool
    let hasResolvedInitialEntitlements: Bool
    let isSelectionDisabled: Bool
    let onUnlockRequest: () -> Void
    let onPreviewSelection: (ThemeGalleryPreviewModel) -> Void

    var body: some View {
        if showsUnlockSection {
            SettingsGalleryUnlockSection(
                message: GameLocalizedStrings.string("settings_theme_gallery_unlock_body"),
                onUnlockRequest: onUnlockRequest
            )
        }

        ForEach(previewModels) { preview in
            let action = selectionAction(for: preview)
            let state = action.galleryOptionState

            Section {
                Button {
                    onPreviewSelection(preview)
                } label: {
                    ThemeGalleryPreviewRow(preview: preview, state: state)
                }
                .buttonStyle(.plain)
                .disabled(isSelectionDisabled || action == .waitForEntitlement)
                .accessibilityLabel(preview.accessibilityDescription)
                .accessibilityValue(state.accessibilityValue)
                .accessibilityInputLabels([preview.name])
                .accessibilityIdentifier("theme_style_option_\(preview.id.rawValue)")
                .accessibilityAddTraits(state == .selected ? .isSelected : [])
            } header: {
                Text(preview.name)
                    .retroSectionHeader()
            }
        }
    }

    private func selectionAction(for preview: ThemeGalleryPreviewModel) -> ThemeGallerySelectionAction {
        ThemeGallerySelectionPolicy.action(
            previewID: preview.id,
            currentThemeID: selectedThemeID,
            isThemePremium: preview.isPremium,
            hasUnlimitedAccess: hasUnlimitedAccess,
            hasResolvedInitialEntitlements: hasResolvedInitialEntitlements
        )
    }
}

enum ThemeGallerySelectionAction: Equatable {
    case none
    case selectTheme
    case waitForEntitlement
    case presentPaywall
}

extension ThemeGallerySelectionAction {
    var galleryOptionState: SettingsGalleryOptionState {
        switch self {
        case .none:
            .selected
        case .selectTheme:
            .available
        case .waitForEntitlement:
            .checkingAccess
        case .presentPaywall:
            .locked
        }
    }
}

enum ThemeGallerySelectionPolicy {
    static func action(
        previewID: ThemeID,
        currentThemeID: ThemeID,
        isThemePremium: Bool,
        hasUnlimitedAccess: Bool,
        hasResolvedInitialEntitlements: Bool
    ) -> ThemeGallerySelectionAction {
        guard previewID != currentThemeID else {
            return .none
        }
        guard isThemePremium else {
            return .selectTheme
        }
        if hasUnlimitedAccess {
            return .selectTheme
        }
        guard hasResolvedInitialEntitlements else {
            return .waitForEntitlement
        }
        return .presentPaywall
    }
}

struct ThemeGalleryPreviewModel: Identifiable {
    let id: ThemeID
    let name: String
    let isPremium: Bool
    let accessibilityDescriptionKey: String
    let accessibilityDescription: String
    let assets: [ThemeGalleryPreviewAsset]
    let palette: ThemeGalleryPreviewPalette

    init(theme: any GameTheme, isIncreaseContrastEnabled: Bool) {
        id = theme.id
        name = theme.name
        isPremium = theme.isPremium
        accessibilityDescriptionKey = Self.accessibilityDescriptionKey(for: theme.id)
        accessibilityDescription = Self.accessibilityDescription(
            forKey: accessibilityDescriptionKey,
            themeName: theme.name
        )
        assets = [
            ThemeGalleryPreviewAsset(
                role: .playerCar,
                assetName: theme.playerCarSprite() ?? ThemeGalleryFallbackAssetName.playerCar
            ),
            ThemeGalleryPreviewAsset(
                role: .rivalCar,
                assetName: theme.rivalCarSprite() ?? ThemeGalleryFallbackAssetName.rivalCar
            ),
            ThemeGalleryPreviewAsset(
                role: .playerHelmet,
                assetName: theme.lifeSprite() ?? ThemeGalleryFallbackAssetName.playerHelmet
            ),
            ThemeGalleryPreviewAsset(
                role: .friendHelmet,
                assetName: theme.resolvedFriendLifeSprite()
            ),
            ThemeGalleryPreviewAsset(
                role: .crash,
                assetName: theme.crashSprite() ?? ThemeGalleryFallbackAssetName.crash
            ),
        ]
        palette = ThemeGalleryPreviewPalette(
            road: theme.gridCellColor(),
            roadLine: theme.roadLineColor(isIncreaseContrastEnabled: isIncreaseContrastEnabled),
            roadExterior: theme.roadExteriorColor() ?? theme.gridCellColor(),
            finishLine: theme.lapMarkerColor(isIncreaseContrastEnabled: isIncreaseContrastEnabled)
        )
    }

    static let genericAccessibilityDescriptionKey = "settings_theme_gallery_preview_accessibility %@"

    private static func accessibilityDescriptionKey(for themeID: ThemeID) -> String {
        switch themeID {
        case .pocket:
            return "settings_theme_gallery_preview_accessibility_pocket"
        case .lcd:
            return "settings_theme_gallery_preview_accessibility_lcd"
        case .eightBit:
            return "settings_theme_gallery_preview_accessibility_eight_bit"
        case .sixteenBit:
            return "settings_theme_gallery_preview_accessibility_sixteen_bit"
        case .thirtyTwoBit:
            return "settings_theme_gallery_preview_accessibility_thirty_two_bit"
        case .sixtyFourBit:
            return "settings_theme_gallery_preview_accessibility_sixty_four_bit"
        default:
            return genericAccessibilityDescriptionKey
        }
    }

    private static func accessibilityDescription(forKey key: String, themeName: String) -> String {
        GameLocalizedStrings.format(key, themeName)
    }
}

struct ThemeGalleryPreviewAsset: Identifiable {
    let role: ThemeGalleryPreviewAssetRole
    let assetName: String

    var id: ThemeGalleryPreviewAssetRole { role }
}

enum ThemeGalleryPreviewAssetRole: CaseIterable, Hashable {
    case playerCar
    case rivalCar
    case playerHelmet
    case friendHelmet
    case crash
}

struct ThemeGalleryPreviewPalette {
    let road: Color
    let roadLine: Color
    let roadExterior: Color
    let finishLine: Color

    var swatches: [ThemeGalleryPaletteSwatch] {
        [
            ThemeGalleryPaletteSwatch(role: .road, color: road),
            ThemeGalleryPaletteSwatch(role: .roadLine, color: roadLine),
            ThemeGalleryPaletteSwatch(role: .roadExterior, color: roadExterior),
            ThemeGalleryPaletteSwatch(role: .finishLine, color: finishLine),
        ]
    }
}

struct ThemeGalleryPaletteSwatch: Identifiable {
    let role: ThemeGalleryPaletteRole
    let color: Color

    var id: ThemeGalleryPaletteRole { role }
}

enum ThemeGalleryPaletteRole: CaseIterable, Hashable {
    case road
    case roadLine
    case roadExterior
    case finishLine
}

private enum ThemeGalleryFallbackAssetName {
    static let playerCar = "playersCar-LCD"
    static let rivalCar = "rivalsCar-LCD"
    static let playerHelmet = "life-LCD"
    static let crash = "crash-LCD"
}

private struct ThemeGalleryPreviewRow: View {
    let preview: ThemeGalleryPreviewModel
    let state: SettingsGalleryOptionState

    @ScaledMetric(relativeTo: .body) private var assetHeight: CGFloat = 52
    @ScaledMetric(relativeTo: .body) private var paletteHeight: CGFloat = 26
    @ScaledMetric(relativeTo: .body) private var stateIconSize: CGFloat = 22

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 14) {
                ThemeGalleryAssetStrip(assets: preview.assets, height: assetHeight)
                ThemeGalleryPaletteBar(palette: preview.palette, height: paletteHeight)
            }

            SettingsGalleryStateIndicator(
                state: state,
                size: stateIconSize,
                reservesSpaceWhenAvailable: true
            )
        }
        .padding(.vertical, 8)
    }
}

private struct ThemeGalleryAssetStrip: View {
    let assets: [ThemeGalleryPreviewAsset]
    let height: CGFloat

    private let sharedBundle = Bundle(for: GameScene.self)

    var body: some View {
        HStack(spacing: 8) {
            ForEach(assets) { asset in
                Image(decorative: asset.assetName, bundle: sharedBundle)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ThemeGalleryPaletteBar: View {
    let palette: ThemeGalleryPreviewPalette
    let height: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(palette.swatches) { swatch in
                Rectangle()
                    .fill(swatch.color)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
        .clipShape(.rect(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        ThemeGalleryView(
            themeManager: ThemeManager(
                configuration: .iPhone,
                userDefaults: .standard,
                hasPremiumAccess: true
            )
        )
        .fontPreferenceStore(FontPreferenceStore(userDefaults: .standard, customFontAvailable: true))
    }
    .environment(StoreKitService())
}
