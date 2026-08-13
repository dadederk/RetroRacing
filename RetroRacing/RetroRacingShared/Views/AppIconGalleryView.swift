//
//  AppIconGalleryView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import SwiftUI

/// Selectable iPhone and iPad gallery for the system app icon.
public struct AppIconGalleryView: View {
    public let appIconService: AppIconService
    public let playLimitService: PlayLimitService?

    @Environment(StoreKitService.self) private var storeKit
    @State private var isShowingPaywall = false
    @State private var isShowingFailure = false

    public init(
        appIconService: AppIconService,
        playLimitService: PlayLimitService? = nil
    ) {
        self.appIconService = appIconService
        self.playLimitService = playLimitService
    }

    public var body: some View {
        List {
            AppIconGallerySections(
                currentIconID: appIconService.currentIconID,
                changingIconID: appIconService.changingIconID,
                showsUnlockSection: storeKit.shouldShowFreeTierAffordances,
                hasUnlimitedAccessForGating: storeKit.hasPremiumAccessForGating,
                hasResolvedInitialEntitlements: storeKit.hasResolvedInitialEntitlements,
                onUnlockRequest: { isShowingPaywall = true },
                onOptionSelection: select
            )
        }
        .navigationTitle(GameLocalizedStrings.string("app_icon_gallery_title"))
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(playLimitService: playLimitService)
        }
        .alert(GameLocalizedStrings.string("app_icon_error_title"), isPresented: $isShowingFailure) {
            Button(GameLocalizedStrings.string("ok"), role: .cancel) {}
        } message: {
            Text(GameLocalizedStrings.string("app_icon_error_message"))
        }
    }

    private func selectionAction(for option: AppIconOption) -> AppIconSelectionAction {
        AppIconSelectionPolicy.action(
            option: option,
            currentIconID: appIconService.currentIconID,
            hasUnlimitedAccessForGating: storeKit.hasPremiumAccessForGating,
            hasResolvedInitialEntitlements: storeKit.hasResolvedInitialEntitlements
        )
    }

    private func select(_ option: AppIconOption) {
        switch selectionAction(for: option) {
        case .none, .waitForEntitlement:
            return
        case .presentPaywall:
            isShowingPaywall = true
        case .selectIcon:
            Task {
                do {
                    try await appIconService.changeIcon(to: option.id)
                } catch AppIconServiceError.changeInProgress {
                    return
                } catch {
                    isShowingFailure = true
                }
            }
        }
    }
}

struct AppIconGallerySections: View {
    let currentIconID: AppIconID?
    let changingIconID: AppIconID?
    let showsUnlockSection: Bool
    let hasUnlimitedAccessForGating: Bool
    let hasResolvedInitialEntitlements: Bool
    let onUnlockRequest: () -> Void
    let onOptionSelection: (AppIconOption) -> Void

    var body: some View {
        if showsUnlockSection {
            SettingsGalleryUnlockSection(
                message: GameLocalizedStrings.string("app_icon_gallery_unlock_body"),
                onUnlockRequest: onUnlockRequest
            )
        }

        ForEach(AppIconGroup.allCases) { group in
            Section {
                ForEach(AppIconCatalog.options(in: group)) { option in
                    let action = selectionAction(for: option)

                    AppIconGalleryRow(
                        option: option,
                        isSelected: option.id == currentIconID,
                        isLocked: action == .presentPaywall,
                        isWaitingForEntitlement: action == .waitForEntitlement,
                        isChanging: option.id == changingIconID,
                        isDisabled: changingIconID != nil || action == .waitForEntitlement,
                        onSelect: { onOptionSelection(option) }
                    )
                }
            } header: {
                Text(group.localizedTitle)
                    .retroSectionHeader()
            }
        }
    }

    private func selectionAction(for option: AppIconOption) -> AppIconSelectionAction {
        AppIconSelectionPolicy.action(
            option: option,
            currentIconID: currentIconID,
            hasUnlimitedAccessForGating: hasUnlimitedAccessForGating,
            hasResolvedInitialEntitlements: hasResolvedInitialEntitlements
        )
    }
}

private struct AppIconGalleryRow: View {
    let option: AppIconOption
    let isSelected: Bool
    let isLocked: Bool
    let isWaitingForEntitlement: Bool
    let isChanging: Bool
    let isDisabled: Bool
    let onSelect: () -> Void

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var previewSize: CGFloat = 104
    @ScaledMetric(relativeTo: .body) private var stateIconSize: CGFloat = 17

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 16))

        Button(action: onSelect) {
            layout {
                preview
                labelAndState
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityInputLabels([option.localizedName])
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var preview: some View {
        Image(decorative: option.previewAssetName)
            .resizable()
            .scaledToFit()
            .frame(width: previewSize, height: previewSize)
            .clipShape(.rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(previewBorderColor, lineWidth: previewBorderWidth)
            }
    }

    private var labelAndState: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(option.localizedName)
                .appFont(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)
            stateIndicator
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var stateIndicator: some View {
        if isChanging {
            ProgressView()
                .controlSize(.small)
                .accessibilityHidden(true)
        } else if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: stateIconSize, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
        } else if isLocked || isWaitingForEntitlement {
            Image(systemName: isWaitingForEntitlement ? "hourglass" : "lock.fill")
                .font(.system(size: stateIconSize, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
        }
    }

    private var previewBorderColor: Color {
        if isSelected {
            return .accentColor
        }
        return .primary.opacity(colorSchemeContrast == .increased ? 0.5 : 0.18)
    }

    private var previewBorderWidth: CGFloat {
        if isSelected {
            return 3
        }
        return colorSchemeContrast == .increased ? 2 : 1
    }

    private var accessibilityValue: String {
        if isChanging {
            return GameLocalizedStrings.string("app_icon_state_changing")
        }
        if isSelected {
            return GameLocalizedStrings.string("app_icon_state_selected")
        }
        if isWaitingForEntitlement {
            return GameLocalizedStrings.string("app_icon_state_checking_access")
        }
        if isLocked {
            return GameLocalizedStrings.string("app_icon_state_requires_unlimited_plays")
        }
        return GameLocalizedStrings.string("app_icon_state_available")
    }

    private var accessibilityLabel: String {
        option.localizedName + ". " + option.localizedAccessibilityDescription
    }
}

#if DEBUG
private struct AppIconGallerySectionsPreview: View {
    let currentIconID: AppIconID
    let changingIconID: AppIconID?
    let showsUnlockSection: Bool
    let hasUnlimitedAccessForGating: Bool
    let hasResolvedInitialEntitlements: Bool

    var body: some View {
        NavigationStack {
            List {
                AppIconGallerySections(
                    currentIconID: currentIconID,
                    changingIconID: changingIconID,
                    showsUnlockSection: showsUnlockSection,
                    hasUnlimitedAccessForGating: hasUnlimitedAccessForGating,
                    hasResolvedInitialEntitlements: hasResolvedInitialEntitlements,
                    onUnlockRequest: {},
                    onOptionSelection: { _ in }
                )
            }
            .navigationTitle(GameLocalizedStrings.string("app_icon_gallery_title"))
        }
    }
}

#Preview("App Icons — Free") {
    AppIconGallerySectionsPreview(
        currentIconID: .classic,
        changingIconID: nil,
        showsUnlockSection: true,
        hasUnlimitedAccessForGating: false,
        hasResolvedInitialEntitlements: true
    )
}

#Preview("App Icons — Unlimited Plays") {
    AppIconGallerySectionsPreview(
        currentIconID: .crt,
        changingIconID: nil,
        showsUnlockSection: false,
        hasUnlimitedAccessForGating: true,
        hasResolvedInitialEntitlements: true
    )
}

#Preview("App Icons — Checking Access") {
    AppIconGallerySectionsPreview(
        currentIconID: .classic,
        changingIconID: nil,
        showsUnlockSection: false,
        hasUnlimitedAccessForGating: false,
        hasResolvedInitialEntitlements: false
    )
}

#Preview("App Icons — Changing") {
    AppIconGallerySectionsPreview(
        currentIconID: .classic,
        changingIconID: .disc,
        showsUnlockSection: false,
        hasUnlimitedAccessForGating: true,
        hasResolvedInitialEntitlements: true
    )
}

#Preview("App Icons — Accessibility Type") {
    AppIconGallerySectionsPreview(
        currentIconID: .retroVideoGame,
        changingIconID: nil,
        showsUnlockSection: false,
        hasUnlimitedAccessForGating: true,
        hasResolvedInitialEntitlements: true
    )
    .dynamicTypeSize(.accessibility3)
}
#endif
