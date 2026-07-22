//
//  GameDifficulty+Codable.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// `GameDifficulty` needs to travel over the SharePlay `GroupSessionMessenger` wire (as part of
/// `SharePlayMatchCommand.roundStart`), so it needs `Codable`. Declared here rather than on the
/// core `GameState.swift` declaration to keep that file focused on gameplay timing.
extension GameDifficulty: Codable {}
