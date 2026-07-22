//
//  SharePlayPlayerRole.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Identifies which of the two SharePlay participants a given device represents.
/// The host is authoritative for round start timing and shared difficulty.
public enum SharePlayPlayerRole: String, Sendable, Equatable, Codable {
    case host
    case guest
}

/// Reason a SharePlay match ended without a normal shared result.
public enum SharePlayAbortReason: String, Sendable, Equatable, Codable {
    /// The remote participant disconnected or the underlying `GroupSession` invalidated.
    case disconnected
    /// Both players failed to confirm a rematch within the retry window.
    case retryTimedOut
    /// The session ended normally (e.g. a player left) outside an active round.
    case sessionEnded
}
