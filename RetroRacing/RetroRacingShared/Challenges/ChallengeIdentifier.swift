//
//  ChallengeIdentifier.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Stable local identifiers for challenge progress tracking.
public enum ChallengeIdentifier: String, CaseIterable, Codable, Sendable {
    // Overtakes in a single completed run
    case runOvertakes100 = "ach.run.overtakes.0100"
    case runOvertakes200 = "ach.run.overtakes.0200"
    case runOvertakes500 = "ach.run.overtakes.0500"
    case runOvertakes600 = "ach.run.overtakes.0600"
    case runOvertakes700 = "ach.run.overtakes.0700"
    case runOvertakes800 = "ach.run.overtakes.0800"

    // Lifetime cumulative overtakes
    case totalOvertakes1k = "ach.total.overtakes.001k"
    case totalOvertakes5k = "ach.total.overtakes.005k"
    case totalOvertakes10k = "ach.total.overtakes.010k"
    case totalOvertakes20k = "ach.total.overtakes.020k"
    case totalOvertakes50k = "ach.total.overtakes.050k"
    case totalOvertakes100k = "ach.total.overtakes.100k"
    case totalOvertakes200k = "ach.total.overtakes.200k"

    // Control-based challenges
    case controlTap = "ach.control.tap"
    case controlSwipe = "ach.control.swipe"
    case controlKeyboard = "ach.control.keyboard"
    case controlVoiceOver = "ach.control.voiceover"
    case controlDigitalCrown = "ach.control.crown"
}
