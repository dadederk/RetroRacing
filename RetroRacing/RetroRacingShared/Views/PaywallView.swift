//
//  PaywallView.swift
//  RetroRacingShared
//
//  Presented when the user hits the daily play limit or from Settings.
//  Inspired by Xarra's paywall tone and structure.
//

import SwiftUI
import StoreKit
#if os(macOS)
import AppKit
#endif

public struct PaywallPreviewData {
    var isLoadingProducts: Bool = false
    var products: [Product] = []
    var hasError: Bool = false
}

public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(StoreKitService.self) private var storeKit
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    private let playLimitService: PlayLimitService?
    private let onPurchaseCompleted: (() -> Void)?

    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var hasLoadedProducts = false
    @State private var showingCharitySafari = false
    @State private var isRestoringPurchases = false
    @State private var restoreMessage: String?
    @State private var showingRestoreAlert = false
    @State private var showingOfferCodeRedemption = false
    #if os(macOS)
    @State private var offerCodeRedemptionHostController: NSViewController?
    @State private var isRedeemingOfferCode = false
    #endif

    private let previewData: PaywallPreviewData?

    private var isPreviewMode: Bool { previewData != nil }

    /// - Parameters:
    ///   - playLimitService: Optional. When provided, `unlockUnlimitedAccess()` is
    ///     called after a successful purchase.
    ///   - onPurchaseCompleted: Optional callback for higher-level coordination.
    ///   - previewData: Optional static data for SwiftUI previews.
    public init(
        playLimitService: PlayLimitService? = nil,
        onPurchaseCompleted: (() -> Void)? = nil,
        previewData: PaywallPreviewData? = nil
    ) {
        self.playLimitService = playLimitService
        self.onPurchaseCompleted = onPurchaseCompleted
        self.previewData = previewData
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    PaywallHeaderView(
                        icon: "gamecontroller.fill",
                        title: GameLocalizedStrings.string("paywall_title"),
                        caption: GameLocalizedStrings.string("paywall_caption_coffee")
                    )

                    productsSection

                    purchaseActions

                    Text(GameLocalizedStrings.string("paywall_unlimited_and_themes"))
                        .font(fontPreferenceStore?.font(textStyle: .subheadline) ?? .subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    // Giving Back (optional charity link)
                    PaywallInfoCard(
                        title: GameLocalizedStrings.string("paywall_giving_back_title"),
                        icon: "heart.fill"
                    ) {
                        Text(.init(GameLocalizedStrings.string("paywall_giving_back_body")))
                    } actionContent: {
                        #if os(iOS)
                        Button {
                            showingCharitySafari = true
                        } label: {
                            PaywallCardLinkLabel(title: GameLocalizedStrings.string("paywall_learn_more"))
                        }
                        .accessibilityRemoveTraits(.isButton)
                        .accessibilityAddTraits(.isLink)
                        #else
                        Button {
                            if let url = ExternalLinks.ammec {
                                openURL(url)
                            }
                        } label: {
                            PaywallCardLinkLabel(title: GameLocalizedStrings.string("paywall_learn_more"))
                        }
                        .accessibilityRemoveTraits(.isButton)
                        .accessibilityAddTraits(.isLink)
                        #endif
                    }

                    // Want to Stay Free?
                    PaywallInfoCard(
                        title: GameLocalizedStrings.string("paywall_stay_free_title"),
                        icon: "info.circle"
                    ) {
                        Text(GameLocalizedStrings.string("paywall_stay_free_body"))
                    } actionContent: {
                        EmptyView()
                    }

                    VStack(spacing: 4) {
                        Text(GameLocalizedStrings.string("paywall_footer_one_time"))
                            .font(fontPreferenceStore?.font(textStyle: .caption2) ?? .caption2)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle(GameLocalizedStrings.string("paywall_go_premium"))
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Label(GameLocalizedStrings.string("paywall_close"), systemImage: "xmark")
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .alert(GameLocalizedStrings.string("purchase_success_title"), isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(GameLocalizedStrings.string("purchase_success_message"))
            }
            .alert(GameLocalizedStrings.string("purchase_error_title"), isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let message = purchaseError {
                    Text(message)
                }
            }
            .alert(GameLocalizedStrings.string("restore_purchases"), isPresented: $showingRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let message = restoreMessage {
                    Text(message)
                }
            }
            .sheet(isPresented: $showingCharitySafari) {
                #if os(iOS)
                if let url = ExternalLinks.ammec {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
                #endif
            }
            #if os(macOS)
            .background {
                OfferCodeRedemptionHostView(controller: $offerCodeRedemptionHostController)
                    .frame(width: 0, height: 0)
            }
            #endif
            .onAppear {
                if isPreviewMode { return }
                if !hasLoadedProducts && !storeKit.isLoadingProducts {
                    hasLoadedProducts = true
                    Task {
                        await storeKit.loadProducts()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var purchaseActions: some View {
        VStack(spacing: 12) {
            redeemCodeButton
            restorePurchasesButton
        }
    }

    @ViewBuilder
    private var redeemCodeButton: some View {
        #if os(iOS)
        Button {
            showingOfferCodeRedemption = true
        } label: {
            Label(GameLocalizedStrings.string("redeem_code"), systemImage: "giftcard")
                .font(fontPreferenceStore?.font(textStyle: .body) ?? .body)
        }
        .buttonStyle(.glass)
        .disabled(isPurchasing || isRestoringPurchases)
        .offerCodeRedemption(isPresented: $showingOfferCodeRedemption) { result in
            if case .success = result {
                Task { await storeKit.refreshPurchasedProducts() }
            }
        }
        #elseif os(macOS)
        Button {
            Task { await redeemOfferCode() }
        } label: {
            HStack {
                if isRedeemingOfferCode {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "giftcard")
                }
                Text(GameLocalizedStrings.string("redeem_code"))
                    .font(fontPreferenceStore?.font(textStyle: .body) ?? .body)
            }
        }
        .buttonStyle(.glass)
        .disabled(isPurchasing || isRestoringPurchases || isRedeemingOfferCode)
        .opacity((isPurchasing || isRestoringPurchases || isRedeemingOfferCode) ? 0.6 : 1.0)
        #else
        EmptyView()
        #endif
    }

    @ViewBuilder
    private var restorePurchasesButton: some View {
        Button {
            Task { await restorePurchases() }
        } label: {
            HStack {
                if isRestoringPurchases {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise.circle")
                }
                Text(GameLocalizedStrings.string("restore_purchases"))
                    .font(fontPreferenceStore?.font(textStyle: .body) ?? .body)
            }
        }
        .buttonStyle(.glass)
        .disabled(isPurchaseActionBusy)
        .opacity(isPurchaseActionBusy ? 0.6 : 1.0)
    }

    private var isPurchaseActionBusy: Bool {
        #if os(macOS)
        return isRestoringPurchases || isPurchasing || isRedeemingOfferCode
        #else
        return isRestoringPurchases || isPurchasing
        #endif
    }

    @ViewBuilder
    private var productsSection: some View {
        if let preview = previewData {
            if preview.isLoadingProducts {
                ProgressView()
                    .padding()
            } else if !preview.products.isEmpty {
                VStack(spacing: 12) {
                    ForEach(preview.products, id: \.id) { product in
                        ProductRow(
                            product: product,
                            state: ProductRowState(
                                hasPurchased: false,
                                isPurchasing: false
                            ),
                            onPurchase: {}
                        )
                    }
                }
            } else if preview.hasError {
                PaywallErrorView(
                    message: GameLocalizedStrings.string("error_product_not_available"),
                    retryAction: {}
                )
            }
        } else {
            if storeKit.isLoadingProducts {
                ProgressView()
                    .padding()
            } else if !storeKit.products.isEmpty {
                VStack(spacing: 12) {
                    ForEach(storeKit.products, id: \.id) { product in
                        ProductRow(
                            product: product,
                            state: ProductRowState(
                                hasPurchased: storeKit.hasPurchased(product.id),
                                isPurchasing: isPurchasing
                            ),
                            onPurchase: {
                                await purchaseProduct(product)
                            }
                        )
                    }
                }
            } else {
                PaywallErrorView(
                    message: GameLocalizedStrings.string("error_product_not_available"),
                    retryAction: {
                        Task { await storeKit.loadProducts() }
                    }
                )
            }
        }
    }

    // MARK: - Purchase flow

    private func purchaseProduct(_ product: Product) async {
        if isPreviewMode { return }

        isPurchasing = true

        do {
            let transaction = try await storeKit.purchase(product)

            if transaction != nil {
                // Mark play limit as unlocked (if available).
                playLimitService?.unlockUnlimitedAccess()
                onPurchaseCompleted?()
                showingSuccess = true
            }
            // If transaction is nil, user cancelled – no UI needed.
        } catch {
            purchaseError = error.localizedDescription
            showingError = true
        }

        isPurchasing = false
    }

    private func restorePurchases() async {
        if isPreviewMode { return }

        isRestoringPurchases = true

        do {
            try await storeKit.restorePurchases()

            if storeKit.hasPremiumAccess {
                playLimitService?.unlockUnlimitedAccess()
                onPurchaseCompleted?()
                restoreMessage = GameLocalizedStrings.string("purchase_restored_success")
            } else {
                restoreMessage = GameLocalizedStrings.string("purchase_restored_none")
            }
            showingRestoreAlert = true
        } catch {
            restoreMessage = GameLocalizedStrings.format("purchase_restored_failed %@", error.localizedDescription)
            showingRestoreAlert = true
        }

        isRestoringPurchases = false
    }

    #if os(macOS)
    @MainActor
    private func redeemOfferCode() async {
        guard let offerCodeRedemptionHostController else {
            purchaseError = GameLocalizedStrings.string("error_product_not_available")
            showingError = true
            return
        }

        isRedeemingOfferCode = true
        defer { isRedeemingOfferCode = false }

        do {
            try await AppStore.presentOfferCodeRedeemSheet(from: offerCodeRedemptionHostController)
            await storeKit.refreshPurchasedProducts()
        } catch {
            purchaseError = error.localizedDescription
            showingError = true
        }
    }
    #endif
}

#if DEBUG
#Preview("Paywall (Loading)") {
    PaywallView(previewData: PaywallPreviewData(isLoadingProducts: true, products: [], hasError: false))
        .environment(StoreKitService())
}
#endif
