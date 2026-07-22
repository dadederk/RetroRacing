//
//  SharePlayMatchStateMachine.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Pure, deterministic transition logic for a 2-player SharePlay match. Has no dependency on
/// GroupActivities or any transport — it only reacts to local gameplay events and incoming
/// `SharePlayMatchCommand` values, and returns the commands the caller should send to the
/// remote participant. This makes it fully unit-testable without a real SharePlay session.
public struct SharePlayMatchStateMachine: Sendable {
    public private(set) var state: SharePlayMatchState = .idle
    public let localRole: SharePlayPlayerRole

    private let countdownDuration: TimeInterval
    private let retryTimeout: TimeInterval
    private let clock: @Sendable () -> Date

    private var localScore = 0
    private var remoteScore = 0
    private var remoteLives = SharePlayMatchCommand.defaultStartingLives
    private var localFinalScore: Int?
    private var remoteFinalScore: Int?
    private var localRetryReady = false
    private var remoteRetryReady = false
    private var remoteSessionReady = false
    private var lastRoundDifficulty: GameDifficulty = .defaultDifficulty

    public init(
        localRole: SharePlayPlayerRole,
        countdownDuration: TimeInterval = 3,
        retryTimeout: TimeInterval = 30,
        clock: @escaping @Sendable () -> Date = Date.init
    ) {
        self.localRole = localRole
        self.countdownDuration = countdownDuration
        self.retryTimeout = retryTimeout
        self.clock = clock
    }

    /// True once the remote participant has sent `.sessionReady`.
    public var isRemoteReady: Bool { remoteSessionReady }

    // MARK: - Local session lifecycle

    /// Call once the session is created/joined and local UI is ready to wait for the opponent.
    @discardableResult
    public mutating func startWaitingForFriend() -> [SharePlayMatchCommand] {
        resetRoundState()
        state = .waitingForFriend
        return [.sessionReady]
    }

    /// Host-only: starts the authoritative countdown once both participants are ready.
    @discardableResult
    public mutating func hostStartRound(difficulty: GameDifficulty) -> [SharePlayMatchCommand] {
        guard localRole == .host else { return [] }
        let startAt = clock().addingTimeInterval(countdownDuration)
        lastRoundDifficulty = difficulty
        state = .countdown(startAt: startAt, difficulty: difficulty)
        return [.roundStart(startAt: startAt, difficulty: difficulty)]
    }

    /// Call once the countdown elapses locally and gameplay actually starts.
    public mutating func beginRound() {
        guard case .countdown(_, let difficulty) = state else { return }
        localScore = 0
        remoteScore = 0
        remoteLives = SharePlayMatchCommand.defaultStartingLives
        state = .inRound(
            difficulty: difficulty,
            localScore: 0,
            remoteScore: 0,
            remoteLives: remoteLives
        )
    }

    // MARK: - Score & elimination (local player)

    @discardableResult
    public mutating func updateLocalScore(_ score: Int, lives: Int) -> [SharePlayMatchCommand] {
        guard case .inRound(let difficulty, _, _, _) = state else { return [] }
        localScore = score
        state = .inRound(
            difficulty: difficulty,
            localScore: score,
            remoteScore: remoteScore,
            remoteLives: remoteLives
        )
        return [.scoreUpdate(score: score, lives: lives)]
    }

    @discardableResult
    public mutating func localPlayerEliminated(finalScore: Int) -> [SharePlayMatchCommand] {
        localScore = finalScore
        localFinalScore = finalScore
        var commands: [SharePlayMatchCommand] = [.playerEliminated(finalScore: finalScore)]
        if let remoteFinalScore {
            commands += finalizeRound(localScore: finalScore, remoteScore: remoteFinalScore)
        } else {
            state = .waitingAfterLocalLoss(remoteScore: remoteScore, localFinalScore: finalScore)
        }
        return commands
    }

    // MARK: - Remote command handling

    @discardableResult
    public mutating func receive(_ command: SharePlayMatchCommand) -> [SharePlayMatchCommand] {
        switch command {
        case .sessionReady:
            remoteSessionReady = true
            return []
        case .roundStart(let startAt, let difficulty):
            guard localRole == .guest else { return [] }
            lastRoundDifficulty = difficulty
            state = .countdown(startAt: startAt, difficulty: difficulty)
            return []
        case .scoreUpdate(let score, let lives):
            return applyRemoteProgress(score: score, lives: lives)
        case .playerEliminated(let finalScore):
            remoteScore = finalScore
            remoteFinalScore = finalScore
            if let localFinalScore {
                return finalizeRound(localScore: localFinalScore, remoteScore: finalScore)
            }
            return []
        case .roundResult(let result):
            state = .finished(result)
            return []
        case .retryReady:
            return receiveRemoteRetryReady()
        case .sessionFinished:
            state = .aborted(reason: .sessionEnded)
            return []
        case .sessionAborted(let reason):
            state = .aborted(reason: reason)
            return []
        }
    }

    // MARK: - Retry handshake

    @discardableResult
    public mutating func retryTapped() -> [SharePlayMatchCommand] {
        localRetryReady = true
        switch state {
        case .finished:
            state = .retryWaiting(localReady: true, remoteReady: remoteRetryReady, deadline: clock().addingTimeInterval(retryTimeout))
        case .retryWaiting(_, let remoteReady, let deadline):
            state = .retryWaiting(localReady: true, remoteReady: remoteReady, deadline: deadline)
        default:
            return []
        }
        return [.retryReady] + advanceRetryHandshakeIfNeeded()
    }

    public mutating func retryTimeoutElapsed() {
        guard case .retryWaiting = state else { return }
        state = .retryTimedOut
    }

    public mutating func disconnected() {
        state = .aborted(reason: .disconnected)
    }

    @discardableResult
    public mutating func leaveSession() -> [SharePlayMatchCommand] {
        state = .idle
        return [.sessionFinished]
    }

    // MARK: - Helpers

    private mutating func applyRemoteProgress(score: Int, lives: Int) -> [SharePlayMatchCommand] {
        remoteScore = score
        remoteLives = lives
        switch state {
        case .inRound(let difficulty, let local, _, _):
            state = .inRound(
                difficulty: difficulty,
                localScore: local,
                remoteScore: score,
                remoteLives: lives
            )
        case .waitingAfterLocalLoss(_, let localFinal):
            state = .waitingAfterLocalLoss(remoteScore: score, localFinalScore: localFinal)
        default:
            break
        }
        return []
    }

    private mutating func receiveRemoteRetryReady() -> [SharePlayMatchCommand] {
        remoteRetryReady = true
        switch state {
        case .finished:
            state = .retryWaiting(localReady: localRetryReady, remoteReady: true, deadline: clock().addingTimeInterval(retryTimeout))
        case .retryWaiting(let localReady, _, let deadline):
            state = .retryWaiting(localReady: localReady, remoteReady: true, deadline: deadline)
        default:
            return []
        }
        return advanceRetryHandshakeIfNeeded()
    }

    private mutating func finalizeRound(localScore: Int, remoteScore: Int) -> [SharePlayMatchCommand] {
        let result: SharePlayRoundResult
        switch localRole {
        case .host:
            result = SharePlayRoundResult(hostScore: localScore, guestScore: remoteScore, difficulty: lastRoundDifficulty)
        case .guest:
            result = SharePlayRoundResult(hostScore: remoteScore, guestScore: localScore, difficulty: lastRoundDifficulty)
        }
        state = .finished(result)
        // Only the host broadcasts the computed result, so both peers converge on a single
        // authoritative payload instead of racing to send potentially-divergent values.
        return localRole == .host ? [.roundResult(result)] : []
    }

    /// When both sides have confirmed retry, resets round state and moves back to waiting.
    private mutating func advanceRetryHandshakeIfNeeded() -> [SharePlayMatchCommand] {
        guard case .retryWaiting(let localReady, let remoteReady, _) = state, localReady, remoteReady else { return [] }
        resetRoundState()
        state = .waitingForFriend
        return []
    }

    private mutating func resetRoundState() {
        localScore = 0
        remoteScore = 0
        remoteLives = SharePlayMatchCommand.defaultStartingLives
        localFinalScore = nil
        remoteFinalScore = nil
        localRetryReady = false
        remoteRetryReady = false
    }
}
