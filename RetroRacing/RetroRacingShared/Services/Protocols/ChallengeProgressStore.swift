//
//  ChallengeProgressStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Persistence abstraction for local challenge progress snapshots.
public protocol ChallengeProgressStore {
    func load() -> ChallengeProgressSnapshot
    func save(_ snapshot: ChallengeProgressSnapshot)
}
