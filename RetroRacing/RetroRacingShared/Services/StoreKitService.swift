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

    // MARK: - Public state

    public private(set) var products: [Product] = []
    public private(set) var purchasedProductIDs: Set<String> = []
    public private(set) var isLoadingProducts = false
    public private(set) var loadError: Error?

    /// Debug premium simulation mode – available in DEBUG and TestFlight builds.
    /// Defaults to production behavior so App Store reviewers experience the free tier.
    public var debugPremiumSimulationMode: DebugPremiumSimulationMode = .productionDefault

    /// Returns true when the user has premium access.
    ///
    /// - `.productionDefault`: uses the real entitlement state from StoreKit.
    /// - `.unlimitedPlays`: always returns `true` for testing.
    /// - `.freemium`: always returns `false` for testing.
    public var hasPremiumAccess: Bool {
        switch debugPremiumSimulationMode {
        case .productionDefault:
            return !purchasedProductIDs.isEmpty
        case .unlimitedPlays:
            return true
        case .freemium:
            return false
        }
    }

    private var transactionUpdateTask: Task<Void, Never>?

    public init() {
        // Start listening for transaction updates immediately
        transactionUpdateTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
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
    }

    // MARK: - Restore / refresh

    public func restorePurchases() async throws {
        // In StoreKit 2, restoring is equivalent to re-reading current entitlements.
        // This is invoked explicitly from the UI for user feedback.
        try await AppStore.sync()
        await updatePurchasedProducts()
    }

    public func refreshPurchasedProducts() async {
        await updatePurchasedProducts()
    }

    // MARK: - Helpers

    public func hasPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
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
}
