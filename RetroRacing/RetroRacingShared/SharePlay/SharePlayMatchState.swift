//
//  SharePlayMatchState.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Drives all SharePlay UI. `GameView`/`GameOverView` render directly from these cases;
/// `.idle` means "no SharePlay match in progress" (regular solo gameplay).
public enum SharePlayMatchState: Sendable, Equatable {
    /// No SharePlay activity. Solo gameplay behaves exactly as before.
    case idle
    /// Session created/joined; waiting for the second participant to be ready.
    case waitingForFriend
    /// Both participants are ready; host-authoritative synchronized countdown before the round starts.
    case countdown(startAt: Date, difficulty: GameDifficulty)
    /// Round in progress. Each device simulates gameplay locally and mirrors score updates.
    case inRound(difficulty: GameDifficulty, localScore: Int, remoteScore: Int, remoteLives: Int)
    /// The local player has been eliminated first and is waiting for the opponent to finish,
    /// with a live view of the opponent's current score.
    case waitingAfterLocalLoss(remoteScore: Int, localFinalScore: Int)
    /// Both players finished; mirrored final result is available to both devices.
    case finished(SharePlayRoundResult)
    /// Post-result rematch handshake; both players must confirm before a new round starts.
    case retryWaiting(localReady: Bool, remoteReady: Bool, deadline: Date)
    /// The 30-second retry handshake elapsed without both players confirming.
    case retryTimedOut
    /// The match ended abnormally (disconnect, retry timeout with no recovery, etc.).
    case aborted(reason: SharePlayAbortReason)

    /// True whenever a SharePlay match (of any kind) is active, i.e. not idle.
    /// Used to gate the daily play limit and lock difficulty editing.
    public var isActive: Bool {
        self != .idle
    }

    /// Stable, privacy-safe label for structured diagnostics. Associated values are intentionally
    /// omitted so logs stay compact while still making transient state flashes traceable.
    public var diagnosticName: String {
        switch self {
        case .idle: return "idle"
        case .waitingForFriend: return "waitingForFriend"
        case .countdown: return "countdown"
        case .inRound: return "inRound"
        case .waitingAfterLocalLoss: return "waitingAfterLocalLoss"
        case .finished: return "finished"
        case .retryWaiting: return "retryWaiting"
        case .retryTimedOut: return "retryTimedOut"
        case .aborted: return "aborted"
        }
    }
}
