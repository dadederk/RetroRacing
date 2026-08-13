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
        let action = selectionAction(for: option)
        logSelection(option: option, action: action)

        switch action {
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

    private func logSelection(option: AppIconOption, action: AppIconSelectionAction) {
        let outcome: AppLog.Outcome
        let reason: String?
        switch action {
        case .none:
            outcome = .ignored
            reason = "already_selected"
        case .selectIcon:
            outcome = .requested
            reason = nil
        case .waitForEntitlement:
            outcome = .deferred
            reason = "entitlement_unresolved"
        case .presentPaywall:
            outcome = .blocked
            reason = "requires_unlimited_plays"
        }

        var fields: [AppLog.Field] = [
            .string("requestedIconID", option.id.rawValue),
            .string("currentIconID", appIconService.currentIconID?.rawValue ?? AppIconID.classic.rawValue),
            .string("selectionAction", action.rawValue),
            .bool("hasUnlimitedAccessForGating", storeKit.hasPremiumAccessForGating),
            .bool("entitlementsResolved", storeKit.hasResolvedInitialEntitlements),
            .bool("systemSupported", appIconService.supportsAlternateIcons),
        ]
        if let reason {
            fields.insert(.reason(reason), at: 0)
        }

        AppLog.info(
            AppLog.assets + AppLog.monetization,
            "APP_ICON_SELECTION",
            outcome: outcome,
            fields: fields
        )
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
                        isSelectionBusy: changingIconID != nil,
                        isDisabled: action == .waitForEntitlement,
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
    let isSelectionBusy: Bool
    let isDisabled: Bool
    let onSelect: () -> Void

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var previewSize: CGFloat = 104
    @ScaledMetric(relativeTo: .body) private var stateIconSize: CGFloat = 20

    var body: some View {
        Button(action: onSelect) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibilityLayout
                } else {
                    standardLayout
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityInputLabels([option.localizedName])
        .accessibilityIdentifier("app_icon_option_\(option.id.rawValue)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        #if os(iOS)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        #endif
    }

    private var preview: some View {
        Image(decorative: option.previewAssetName)
            .resizable()
            .scaledToFit()
            .frame(width: resolvedPreviewSize, height: resolvedPreviewSize)
            .clipShape(.rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(previewBorderColor, lineWidth: previewBorderWidth)
            }
    }

    private var standardLayout: some View {
        HStack(alignment: .center, spacing: 16) {
            preview
            nameLabel
            Spacer(minLength: 4)
            stateIndicator
        }
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                preview
                Spacer(minLength: 4)
                stateIndicator
            }
            nameLabel
        }
    }

    private var nameLabel: some View {
        Text(option.localizedName)
            .appFont(.body)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var stateIndicator: some View {
        if isChanging {
            ProgressView()
                .controlSize(.large)
                .accessibilityHidden(true)
        } else if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: stateIconSize, weight: .semibold))
                .foregroundStyle(.pink)
                .accessibilityHidden(true)
        } else if isLocked || isWaitingForEntitlement {
            Image(systemName: isWaitingForEntitlement ? "hourglass" : "lock.fill")
                .font(.system(size: stateIconSize, weight: .semibold))
                .foregroundStyle(.pink)
                .accessibilityHidden(true)
        }
    }

    private var resolvedPreviewSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? min(previewSize, 180) : previewSize
    }

    private var previewBorderColor: Color {
        if isSelected {
            return .primary
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
        if isSelectionBusy {
            return GameLocalizedStrings.string("app_icon_state_another_change_in_progress")
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
