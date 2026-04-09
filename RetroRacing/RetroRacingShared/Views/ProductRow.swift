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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button {
            guard !state.hasPurchased, !state.isPurchasing else { return }
            Task {
                await onPurchase()
            }
        } label: {
            let layout: AnyLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(spacing: 12))

            layout {
                VStack(alignment: .leading, spacing: 4) {
                    Text(GameLocalizedStrings.string("product_unlimited_plays"))
                        .font(fontPreferenceStore?.font(textStyle: .headline) ?? .headline)
                    if state.hasPurchased {
                        Text(GameLocalizedStrings.string("purchase_success_message"))
                            .font(fontPreferenceStore?.font(textStyle: .subheadline) ?? .subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(product.description)
                            .font(fontPreferenceStore?.font(textStyle: .subheadline) ?? .subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trailingContent
            }
            .padding()
            .background(.thinMaterial)
            .roundedBorder(.secondary, lineWidth: 1, cornerRadius: 12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var trailingContent: some View {
        if state.isPurchasing {
            ProgressView()
                .progressViewStyle(.circular)
        } else if state.hasPurchased {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color.accentColor)
                .accessibilityRemoveTraits(.isSelected)
                .accessibilityHidden(true)
        } else {
            Text(product.displayPrice)
                .font(fontPreferenceStore?.font(textStyle: .subheadline) ?? .subheadline)
                .foregroundStyle(Color.accentColor)
        }
    }
}
