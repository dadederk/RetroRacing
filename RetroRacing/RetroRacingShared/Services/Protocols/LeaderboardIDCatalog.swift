//
//  LeaderboardIDCatalog.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Supported leaderboard platform namespaces in App Store Connect.
public enum LeaderboardPlatform: String, CaseIterable, Sendable {
    case iPhone
    case iPad
    case macOS
    case tvOS
    case watchOS
}

/// Single source of truth for all Game Center leaderboard identifiers.
public enum LeaderboardIDCatalog {
    public static func leaderboardID(
        platform: LeaderboardPlatform,
        difficulty: GameDifficulty
    ) -> String {
        switch platform {
        case .iPhone:
            switch difficulty {
            case .cruise:
                return "bestios001cruise"
            case .fast:
                return "bestios001fast"
            case .rapid:
                return "bestios001test"
            @unknown default:
                return "bestios001test"
            }
        case .iPad:
            switch difficulty {
            case .cruise:
                return "bestipad001cruise"
            case .fast:
                return "bestipad001fast"
            case .rapid:
                return "bestipad001test"
            @unknown default:
                return "bestipad001test"
            }
        case .macOS:
            switch difficulty {
            case .cruise:
                return "bestmacos001cruise"
            case .fast:
                return "bestmacos001fast"
            case .rapid:
                return "bestmacos001test"
            @unknown default:
                return "bestmacos001test"
            }
        case .tvOS:
            switch difficulty {
            case .cruise:
                return "besttvos001cruise"
            case .fast:
                return "besttvos001fast"
            case .rapid:
                return "besttvos001"
            @unknown default:
                return "besttvos001"
            }
        case .watchOS:
            switch difficulty {
            case .cruise:
                return "bestwatchos001cruise"
            case .fast:
                return "bestwatchos001fast"
            case .rapid:
                return "bestwatchos001test"
            @unknown default:
                return "bestwatchos001test"
            }
        }
    }
}

/// Shared watchOS leaderboard configuration so watch and companion flows cannot drift.
public struct LeaderboardConfigurationWatchOS: LeaderboardConfiguration {
    public init() {}

    public func leaderboardID(for difficulty: GameDifficulty) -> String {
        LeaderboardIDCatalog.leaderboardID(platform: .watchOS, difficulty: difficulty)
    }
}
