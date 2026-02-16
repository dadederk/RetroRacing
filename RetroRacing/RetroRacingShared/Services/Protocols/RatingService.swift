//
//  RatingService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Interface for requesting StoreKit ratings and gating prompts based on gameplay context.
public protocol RatingService {
    /// Requests the native in-app StoreKit rating prompt.
    func requestRating()

    /// Records a best-score improvement and requests a rating prompt when eligibility criteria are met.
    func recordBestScoreImprovementAndRequestIfEligible()
}
