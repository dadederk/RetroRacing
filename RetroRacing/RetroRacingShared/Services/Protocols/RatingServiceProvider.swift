//
//  RatingServiceProvider.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Platform-specific implementation for presenting the app store review UI.
public protocol RatingServiceProvider {
    func presentRatingRequest()
}
