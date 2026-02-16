//
//  AppStoreReviewURL.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 16/02/2026.
//

import Foundation

/// Centralized App Store URL used by manual "Rate the app" entry points.
public enum AppStoreReviewURL {
    public static var writeReview: URL? {
        URL(string: "https://apps.apple.com/app/id6758641625?action=write-review")
    }
}
