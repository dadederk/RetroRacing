//
//  PaywallView.swift
//  RetroRacingShared
//
//  Presented when the user hits the daily play limit or from Settings.
//  Inspired by Xarra's paywall tone and structure.
//

import SwiftUI
import StoreKit

public struct PaywallPreviewData {
    var isLoadingProducts: Bool = false
    var products: [Product] = []
    var hasError: Bool = false
}

public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
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

                    restorePurchasesButton

                    Text(GameLocalizedStrings.string("paywall_unlimited_and_themes"))
                        .font(fontPreferenceStore?.subheadlineFont ?? .subheadline)
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
                        EmptyView()
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
                            .font(fontPreferenceStore?.caption2Font ?? .caption2)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle(GameLocalizedStrings.string("paywall_go_premium"))
            .navigationBarTitleDisplayMode(.inline)
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
                if let url = URL(string: "https://www.ammec.org/") {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
                #endif
            }
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
    private var restorePurchasesButton: some View {
        Button {
            Task { await restorePurchases() }
        } label: {
            HStack {
                if isRestoringPurchases {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                }
                Text(GameLocalizedStrings.string("restore_purchases"))
                    .font(fontPreferenceStore?.bodyFont ?? .body)
            }
        }
        .buttonStyle(.glass)
        .disabled(isRestoringPurchases || isPurchasing)
        .opacity((isRestoringPurchases || isPurchasing) ? 0.6 : 1.0)
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
}

#if DEBUG
#Preview("Paywall (Loading)") {
    PaywallView(previewData: PaywallPreviewData(isLoadingProducts: true, products: [], hasError: false))
        .environment(StoreKitService())
}
#endif

