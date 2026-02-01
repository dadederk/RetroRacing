//
//  RatingServiceProvider.swift
//  RetroRacing
//
//  Created by Dani on 30/01/2026.
//

import Foundation

protocol RatingServiceProvider {
    /// Request app store review using platform-specific implementation
    func presentRatingRequest()
}
