//
//  SharePlayGuestSpeedRestore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Tracks the guest's original local `GameDifficulty` selection across a SharePlay session so
/// it can be restored once the session ends. The host always plays at their own selected speed
/// (it defines the shared round conditions); the guest temporarily adopts the host's speed for
/// the duration of the match and reverts to their own preference afterward.
public struct SharePlayGuestSpeedRestore: Sendable, Equatable {
    private var capturedDifficulty: GameDifficulty?

    public init() {}

    /// True once a value has been captured and not yet consumed/restored.
    public var hasCapturedValue: Bool {
        capturedDifficulty != nil
    }

    /// Call before applying the host's shared speed on a guest device. Captures the guest's
    /// current local difficulty exactly once per session; subsequent calls are no-ops so an
    /// in-progress match never overwrites the original value with the host's speed.
    public mutating func captureIfNeeded(currentDifficulty: GameDifficulty) {
        guard capturedDifficulty == nil else { return }
        capturedDifficulty = currentDifficulty
    }

    /// Returns the previously captured difficulty (if any) so the caller can restore it as the
    /// guest's local selection, clearing the capture. Safe to call multiple times: returns
    /// `nil` once already consumed or if nothing was ever captured (e.g. on the host, or when
    /// SharePlay was never used).
    public mutating func consumeRestoreValue() -> GameDifficulty? {
        defer { capturedDifficulty = nil }
        return capturedDifficulty
    }
}
