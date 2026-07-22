//
//  StoreKitService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import Foundation
import StoreKit
import Observation

/// StoreKit 2 wrapper for the RetroRacing monetization model.
///
/// - One non-consumable product: unlimited plays forever.
/// - Uses on-device cryptographic verification (no server).
/// - Exposes a simple `hasPremiumAccess` flag that can be used by
///   the play limit service, theme manager, and UI.
@MainActor
@Observable
public final class StoreKitService {
    // MARK: - Product identifiers

    public enum ProductID: String, CaseIterable {
        case unlimitedPlays = "com.accessibilityUpTo11.RetroRacing.unlimitedPlays"
    }

    public enum DebugPremiumSimulationMode: Int, CaseIterable, Sendable {
        case productionDefault
        case unlimitedPlays
        case freemium
    }

    enum DebugStorageKeys {
        static let forceFreemiumPlayLimit = "PlayLimit.debugForceFreemium"
    }

    enum StorageKeys {
        static let cachedPremiumAccess = "StoreKit.cachedPremiumAccess"
        static let lastEntitlementCheck = "StoreKit.lastEntitlementCheck"
    }

    public enum PurchaseFlowError: LocalizedError, Sendable {
        case unsupportedPlatform

        public var errorDescription: String? {
            "Purchases are not supported on this platform."
        }
    }

    // MARK: - Public state

    public private(set) var products: [Product] = []
    public private(set) var purchasedProductIDs: Set<String> = []
    public private(set) var isLoadingProducts = false
    public private(set) var loadError: Error?

    /// Whether the first on-device entitlement check (`Transaction.currentEntitlements`) has completed.
    public private(set) var hasResolvedInitialEntitlements = false

    /// Last known premium state persisted locally, seeded at launch before the first live check.
    public private(set) var cachedPremiumAccess = false

    /// Invoked whenever live entitlements are refreshed with the real StoreKit result
    /// (`!purchasedProductIDs.isEmpty`), not the debug-simulated `hasPremiumAccess`.
    public var onEntitlementsUpdated: (@MainActor (Bool) -> Void)?

    private let userDefaults: UserDefaults
    private let isDebugSimulationEnabled: Bool

    /// Debug premium simulation mode – available in DEBUG builds.
    /// Defaults to production behavior so App Store reviewers experience the free tier.
    public var debugPremiumSimulationMode: DebugPremiumSimulationMode = .productionDefault {
        didSet {
            guard isDebugSimulationEnabled else {
                if debugPremiumSimulationMode != .productionDefault {
                    debugPremiumSimulationMode = .productionDefault
                    return
                }
                syncPlayLimitDebugMode()
                return
            }
            syncPlayLimitDebugMode()
        }
    }

    /// Returns true when the user has premium access.
    ///
    /// - `.productionDefault`: uses the real entitlement state from StoreKit.
    /// - `.unlimitedPlays`: always returns `true` for testing.
    /// - `.freemium`: always returns `false` for testing.
    public var hasPremiumAccess: Bool {
        guard isDebugSimulationEnabled else {
            return !purchasedProductIDs.isEmpty
        }

        switch debugPremiumSimulationMode {
        case .productionDefault:
            return !purchasedProductIDs.isEmpty
        case .unlimitedPlays:
            return true
        case .freemium:
            return false
        }
    }

    /// Premium access for play bypass and premium UI chrome. Before the initial entitlement check
    /// resolves, falls back to the locally cached premium state so returning purchasers are never
    /// briefly treated as free users.
    public var hasPremiumAccessForGating: Bool {
        guard hasResolvedInitialEntitlements else {
            return cachedPremiumAccess || hasPremiumAccess
        }
        return hasPremiumAccess
    }

    /// True once the initial entitlement check has completed and the user does not have premium access.
    /// Free-tier affordances (Support CTA, play-limit section, purchase CTAs) should gate on this
    /// rather than on `hasPremiumAccess` directly, to avoid a spurious flash for premium users
    /// while StoreKit is still resolving on cold launch.
    public var shouldShowFreeTierAffordances: Bool {
        hasResolvedInitialEntitlements && !hasPremiumAccess
    }

    private var transactionUpdateTask: Task<Void, Never>?

    /// - Parameters:
    ///   - userDefaults: Backing store for debug simulation coordination. Defaults to `InfrastructureDefaults.userDefaults`.
    ///   - isDebugSimulationEnabled: Enables simulation overrides. Defaults to `BuildConfiguration.isDebug`.
    ///   - refreshEntitlementsOnInit: When `true`, starts an independent entitlement refresh on launch.
    public init(
        userDefaults: UserDefaults = InfrastructureDefaults.userDefaults,
        isDebugSimulationEnabled: Bool = BuildConfiguration.isDebug,
        refreshEntitlementsOnInit: Bool = true
    ) {
        self.userDefaults = userDefaults
        self.isDebugSimulationEnabled = isDebugSimulationEnabled
        cachedPremiumAccess = userDefaults.bool(forKey: StorageKeys.cachedPremiumAccess)
        syncPlayLimitDebugMode()

        // Start listening for transaction updates immediately
        transactionUpdateTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }

        if refreshEntitlementsOnInit {
            Task { [weak self] in
                await self?.updatePurchasedProducts()
            }
        }
    }

    // MARK: - Loading products

    public func loadProducts() async {
        guard !isLoadingProducts else { return }

        isLoadingProducts = true
        loadError = nil

        do {
            products = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            await updatePurchasedProducts()
        } catch {
            loadError = error
        }

        isLoadingProducts = false
    }

    // MARK: - Purchasing

    @discardableResult
    public func purchase(_ product: Product) async throws -> Transaction? {
        #if os(visionOS)
        throw PurchaseFlowError.unsupportedPlatform
        #else
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction

        case .userCancelled, .pending:
            return nil

        @unknown default:
            return nil
        }
        #endif
    }

    // MARK: - Restore / refresh

    public func restorePurchases() async throws {
        #if os(visionOS)
        throw PurchaseFlowError.unsupportedPlatform
        #else
        // In StoreKit 2, restoring is equivalent to re-reading current entitlements.
        // This is invoked explicitly from the UI for user feedback.
        try await AppStore.sync()
        await updatePurchasedProducts()
        #endif
    }

    public func refreshPurchasedProducts() async {
        await updatePurchasedProducts()
    }

    // MARK: - Helpers

    /// Returns whether the given product ID has been purchased.
    ///
    /// Respects `debugPremiumSimulationMode` the same way `hasPremiumAccess` does,
    /// so freemium mode returns `false` and unlimited-plays mode returns `true`
    /// for the unlimited plays product regardless of real entitlement state.
    public func hasPurchased(_ productID: String) -> Bool {
        guard isDebugSimulationEnabled else {
            return purchasedProductIDs.contains(productID)
        }

        switch debugPremiumSimulationMode {
        case .productionDefault:
            return purchasedProductIDs.contains(productID)
        case .unlimitedPlays:
            return productID == ProductID.unlimitedPlays.rawValue
        case .freemium:
            return false
        }
    }

    // MARK: - Private

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            purchased.insert(transaction.productID)
        }

        purchasedProductIDs = purchased
        hasResolvedInitialEntitlements = true
        persistPremiumCache(isPremium: !purchased.isEmpty)
        onEntitlementsUpdated?(!purchased.isEmpty)
    }

    private func persistPremiumCache(isPremium: Bool) {
        cachedPremiumAccess = isPremium
        userDefaults.set(isPremium, forKey: StorageKeys.cachedPremiumAccess)
        userDefaults.set(Date(), forKey: StorageKeys.lastEntitlementCheck)
    }

    /// Observes the transaction updates stream to handle purchases completed outside the app,
    /// on other devices, or while the app was closed.
    private func observeTransactionUpdates() async {
        for await verificationResult in Transaction.updates {
            guard case .verified(let transaction) = verificationResult else {
                continue
            }

            // Update purchased products when a new transaction arrives
            await updatePurchasedProducts()

            // Finish the transaction
            await transaction.finish()
        }
    }

    private func syncPlayLimitDebugMode() {
        let shouldForceFreemium = isDebugSimulationEnabled && debugPremiumSimulationMode == .freemium
        userDefaults.set(
            shouldForceFreemium,
            forKey: DebugStorageKeys.forceFreemiumPlayLimit
        )
    }
}
