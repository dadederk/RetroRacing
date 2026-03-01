//
//  ChallengeControlInput.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Control methods that can qualify control-based challenges.
public enum ChallengeControlInput: String, CaseIterable, Codable, Sendable {
    case tap
    case swipe
    case keyboard
    case voiceOver
    case digitalCrown
}
