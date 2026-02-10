//
//  ProductRow.swift
//  RetroRacingShared
//
//  Simple product card UI for the Unlimited Plays non-consumable.
//

import SwiftUI
import StoreKit

struct ProductRowState {
    var hasPurchased: Bool
    var isPurchasing: Bool
}

struct ProductRow: View {
    let product: Product
    let state: ProductRowState
    let onPurchase: () async -> Void
    
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    var body: some View {
        Button {
            guard !state.hasPurchased, !state.isPurchasing else { return }
            Task {
                await onPurchase()
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(GameLocalizedStrings.string("product_unlimited_plays"))
                        .font(fontPreferenceStore?.headlineFont ?? .headline)
                    if state.hasPurchased {
                        Text(GameLocalizedStrings.string("play_limit_unlimited"))
                            .font(fontPreferenceStore?.subheadlineFont ?? .subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(product.displayPrice)
                            .font(fontPreferenceStore?.subheadlineFont ?? .subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if state.isPurchasing {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if state.hasPurchased {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.accentColor)
                } else {
                    Text(product.displayPrice)
                        .font(fontPreferenceStore?.subheadlineFont ?? .subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(.thinMaterial)
            .roundedBorder(.secondary, lineWidth: 1, cornerRadius: 12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

