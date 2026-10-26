//
//  AppStoreReviewURL.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 16/02/2026.
//

import Foundation

/// Centralized App Store URLs used by manual "Rate the app" entry points.
public enum AppStoreReviewURL {
    private static let productURL = "https://apps.apple.com/app/id6758641625"

    public static var writeReview: URL? {
        URL(string: "\(productURL)?action=write-review")
    }

    public static var productPage: URL? {
        URL(string: productURL)
    }
}
