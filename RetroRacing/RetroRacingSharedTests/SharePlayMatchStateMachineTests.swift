//
//  SharePlayMatchStateMachineTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 22/07/2026.
//

import XCTest
@testable import RetroRacingShared

final class SharePlayMatchStateMachineTests: XCTestCase {

    private let fixedNow = Date(timeIntervalSinceReferenceDate: 1_000)

    private func makeMachine(role: SharePlayPlayerRole) -> SharePlayMatchStateMachine {
        SharePlayMatchStateMachine(localRole: role, countdownDuration: 3, retryTimeout: 30, clock: { self.fixedNow })
    }

    // MARK: - Session lifecycle

    func testGivenIdleWhenStartWaitingForFriendThenStateIsWaitingAndSessionReadyIsSent() {
        // Given
        var machine = makeMachine(role: .host)

        // When
        let commands = machine.startWaitingForFriend()

        // Then
        XCTAssertEqual(machine.state, .waitingForFriend)
        XCTAssertEqual(commands, [.sessionReady])
    }

    func testGivenWaitingWhenResendingSessionReadyThenSessionReadyIsSentWithoutChangingState() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()

        // When
        let commands = machine.resendSessionReadyIfWaitingForFriend()

        // Then
        XCTAssertEqual(machine.state, .waitingForFriend)
        XCTAssertEqual(commands, [.sessionReady])
    }

    func testGivenNotWaitingWhenResendingSessionReadyThenNoCommandIsSent() {
        // Given
        let machine = makeMachine(role: .host)

        // When
        let commands = machine.resendSessionReadyIfWaitingForFriend()

        // Then
        XCTAssertTrue(commands.isEmpty)
        XCTAssertEqual(machine.state, .idle)
    }

    func testGivenGuestWhenHostStartRoundCalledThenNoCommandsAreSent() {
        // Given
        var machine = makeMachine(role: .guest)
        machine.startWaitingForFriend()

        // When
        let commands = machine.hostStartRound(difficulty: .fast)

        // Then
        XCTAssertTrue(commands.isEmpty)
        XCTAssertEqual(machine.state, .waitingForFriend)
    }

    func testGivenHostWaitingWhenHostStartRoundThenCountdownStateAndRoundStartCommandSent() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()

        // When
        let commands = machine.hostStartRound(difficulty: .rapid)

        // Then
        let expectedStartAt = fixedNow.addingTimeInterval(3)
        XCTAssertEqual(machine.state, .countdown(startAt: expectedStartAt, difficulty: .rapid))
        XCTAssertEqual(commands, [.roundStart(startAt: expectedStartAt, difficulty: .rapid)])
    }

    func testGivenHostNotWaitingWhenHostStartRoundThenNoCommandIsSent() {
        // Given
        var machine = makeMachine(role: .host)

        // When
        let commands = machine.hostStartRound(difficulty: .rapid)

        // Then
        XCTAssertTrue(commands.isEmpty)
        XCTAssertEqual(machine.state, .idle)
    }

    func testGivenGuestWhenReceivingRoundStartThenCountdownStateIsSet() {
        // Given
        var machine = makeMachine(role: .guest)
        machine.startWaitingForFriend()
        let startAt = fixedNow.addingTimeInterval(3)

        // When
        machine.receive(.roundStart(startAt: startAt, difficulty: .cruise))

        // Then
        XCTAssertEqual(machine.state, .countdown(startAt: startAt, difficulty: .cruise))
    }

    func testGivenGuestAlreadyInRoundWhenReceivingStaleRoundStartThenStateIsUnchanged() {
        // Given
        var machine = makeMachine(role: .guest)
        machine.startWaitingForFriend()
        machine.receive(.roundStart(startAt: fixedNow, difficulty: .fast))
        machine.beginRound()

        // When
        machine.receive(.roundStart(startAt: fixedNow.addingTimeInterval(10), difficulty: .rapid))

        // Then
        XCTAssertEqual(machine.state, .inRound(difficulty: .fast, localScore: 0, remoteScore: 0, remoteLives: 3))
    }

    func testGivenCountdownWhenBeginRoundThenStateIsInRoundWithZeroScores() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()
        machine.hostStartRound(difficulty: .fast)

        // When
        machine.beginRound()

        // Then
        XCTAssertEqual(machine.state, .inRound(difficulty: .fast, localScore: 0, remoteScore: 0, remoteLives: 3))
    }

    func testGivenSessionReadyReceivedThenIsRemoteReadyBecomesTrue() {
        // Given
        var machine = makeMachine(role: .host)
        XCTAssertFalse(machine.isRemoteReady)

        // When
        machine.receive(.sessionReady)

        // Then
        XCTAssertTrue(machine.isRemoteReady)
    }

    // MARK: - Score & elimination

    func testGivenNotInRoundWhenUpdateLocalScoreThenNoCommandIsSent() {
        // Given
        var machine = makeMachine(role: .host)

        // When
        let commands = machine.updateLocalScore(10, lives: 3)

        // Then
        XCTAssertTrue(commands.isEmpty)
    }

    func testGivenInRoundWhenUpdateLocalScoreThenStateReflectsScoreAndCommandIsSent() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()
        machine.hostStartRound(difficulty: .fast)
        machine.beginRound()

        // When
        let commands = machine.updateLocalScore(42, lives: 2)

        // Then
        XCTAssertEqual(machine.state, .inRound(difficulty: .fast, localScore: 42, remoteScore: 0, remoteLives: 3))
        XCTAssertEqual(commands, [.scoreUpdate(score: 42, lives: 2)])
    }

    func testGivenInRoundWhenLocalEliminatedBeforeRemoteThenWaitsWithLiveRemoteScore() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()
        machine.hostStartRound(difficulty: .fast)
        machine.beginRound()
        machine.receive(.scoreUpdate(score: 5, lives: 2))

        // When
        let commands = machine.localPlayerEliminated(finalScore: 20)

        // Then
        XCTAssertEqual(machine.state, .waitingAfterLocalLoss(remoteScore: 5, localFinalScore: 20))
        XCTAssertEqual(commands, [.playerEliminated(finalScore: 20)])
    }

    func testGivenWaitingAfterLocalLossWhenRemoteScoreUpdatesThenLiveRemoteScoreReflectsIt() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()
        machine.hostStartRound(difficulty: .fast)
        machine.beginRound()
        machine.localPlayerEliminated(finalScore: 20)

        // When
        machine.receive(.scoreUpdate(score: 33, lives: 1))

        // Then
        XCTAssertEqual(machine.state, .waitingAfterLocalLoss(remoteScore: 33, localFinalScore: 20))
    }

    func testGivenHostWhenBothPlayersEliminatedThenHostBroadcastsRoundResult() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()
        machine.hostStartRound(difficulty: .fast)
        machine.beginRound()
        machine.localPlayerEliminated(finalScore: 30)

        // When
        let commands = machine.receive(.playerEliminated(finalScore: 18))

        // Then
        let expectedResult = SharePlayRoundResult(hostScore: 30, guestScore: 18, difficulty: .fast)
        XCTAssertEqual(machine.state, .finished(expectedResult))
        XCTAssertEqual(commands, [.roundResult(expectedResult)])
    }

    func testGivenInRoundWhenRemoteEliminatedBeforeLocalThenVisibleRemoteLivesAreZero() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()
        machine.hostStartRound(difficulty: .fast)
        machine.beginRound()
        machine.updateLocalScore(30, lives: 2)

        // When
        let commands = machine.receive(.playerEliminated(finalScore: 18))

        // Then
        XCTAssertEqual(machine.state, .inRound(difficulty: .fast, localScore: 30, remoteScore: 18, remoteLives: 0))
        XCTAssertTrue(commands.isEmpty)
    }

    func testGivenGuestWhenBothPlayersEliminatedThenGuestDoesNotBroadcastRoundResult() {
        // Given
        var machine = makeMachine(role: .guest)
        machine.startWaitingForFriend()
        machine.receive(.roundStart(startAt: fixedNow, difficulty: .fast))
        machine.beginRound()
        machine.localPlayerEliminated(finalScore: 18)

        // When
        let commands = machine.receive(.playerEliminated(finalScore: 30))

        // Then
        let expectedResult = SharePlayRoundResult(hostScore: 30, guestScore: 18, difficulty: .fast)
        XCTAssertEqual(machine.state, .finished(expectedResult))
        XCTAssertTrue(commands.isEmpty)
    }

    func testGivenGuestWhenReceivingRoundResultThenStateMirrorsExactHostPayload() {
        // Given
        var machine = makeMachine(role: .guest)
        machine.startWaitingForFriend()
        machine.receive(.roundStart(startAt: fixedNow, difficulty: .rapid))
        machine.beginRound()
        machine.localPlayerEliminated(finalScore: 40)
        let result = SharePlayRoundResult(hostScore: 55, guestScore: 40, difficulty: .rapid)

        // When
        machine.receive(.roundResult(result))

        // Then
        XCTAssertEqual(machine.state, .finished(result))
    }

    func testGivenRetryWaitingWhenReceivingStaleRoundResultThenStateIsUnchanged() {
        // Given
        var machine = finishedMachine(role: .guest)
        machine.retryTapped()
        let staleResult = SharePlayRoundResult(hostScore: 55, guestScore: 40, difficulty: .rapid)

        // When
        machine.receive(.roundResult(staleResult))

        // Then
        guard case .retryWaiting(let localReady, let remoteReady, _) = machine.state else {
            return XCTFail("Expected retryWaiting state")
        }
        XCTAssertTrue(localReady)
        XCTAssertFalse(remoteReady)
    }

    // MARK: - Winner/tie computation

    func testGivenHostScoreHigherThenLocalOutcomeIsWonForHostAndLostForGuest() {
        // Given
        let result = SharePlayRoundResult(hostScore: 100, guestScore: 40, difficulty: .fast)

        // Then
        XCTAssertEqual(result.outcome, .hostWon)
        XCTAssertEqual(result.localOutcome(for: .host), .won)
        XCTAssertEqual(result.localOutcome(for: .guest), .lost)
    }

    func testGivenEqualScoresThenLocalOutcomeIsTieForBothRoles() {
        // Given
        let result = SharePlayRoundResult(hostScore: 70, guestScore: 70, difficulty: .fast)

        // Then
        XCTAssertEqual(result.outcome, .tie)
        XCTAssertEqual(result.localOutcome(for: .host), .tie)
        XCTAssertEqual(result.localOutcome(for: .guest), .tie)
    }

    // MARK: - Retry handshake

    func testGivenFinishedWhenLocalRetryTappedFirstThenWaitingWithOnlyLocalReady() {
        // Given
        var machine = finishedMachine(role: .host)

        // When
        let commands = machine.retryTapped()

        // Then
        XCTAssertEqual(commands, [.retryReady])
        guard case .retryWaiting(let localReady, let remoteReady, _) = machine.state else {
            return XCTFail("Expected retryWaiting state")
        }
        XCTAssertTrue(localReady)
        XCTAssertFalse(remoteReady)
    }

    func testGivenFinishedWhenBothPlayersRetryThenStateResetsToWaitingForFriend() {
        // Given
        var machine = finishedMachine(role: .host)
        machine.retryTapped()

        // When
        machine.receive(.retryReady)

        // Then
        XCTAssertEqual(machine.state, .waitingForFriend)
    }

    func testGivenFinishedWhenRemoteRetriesFirstThenWaitingWithOnlyRemoteReady() {
        // Given
        var machine = finishedMachine(role: .host)

        // When
        machine.receive(.retryReady)

        // Then
        guard case .retryWaiting(let localReady, let remoteReady, _) = machine.state else {
            return XCTFail("Expected retryWaiting state")
        }
        XCTAssertFalse(localReady)
        XCTAssertTrue(remoteReady)
    }

    func testGivenRemoteRetriedFirstWhenLocalRetriesThenStateResetsToWaitingForFriend() {
        // Given
        var machine = finishedMachine(role: .host)
        machine.receive(.retryReady)

        // When
        machine.retryTapped()

        // Then
        XCTAssertEqual(machine.state, .waitingForFriend)
    }

    func testGivenRetryWaitingWhenTimeoutElapsesThenStateIsRetryTimedOut() {
        // Given
        var machine = finishedMachine(role: .host)
        machine.retryTapped()

        // When
        let commands = machine.retryTimeoutElapsed()

        // Then
        XCTAssertEqual(machine.state, .retryTimedOut)
        XCTAssertEqual(commands, [.sessionAborted(reason: .retryTimedOut)])
    }

    func testGivenNotRetryWaitingWhenTimeoutElapsedThenStateIsUnchanged() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()

        // When
        let commands = machine.retryTimeoutElapsed()

        // Then
        XCTAssertEqual(machine.state, .waitingForFriend)
        XCTAssertTrue(commands.isEmpty)
    }

    // MARK: - Disconnect & session end

    func testGivenAnyStateWhenDisconnectedThenStateIsAbortedWithDisconnectedReason() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()

        // When
        machine.disconnected()

        // Then
        XCTAssertEqual(machine.state, .aborted(reason: .disconnected))
    }

    func testGivenActiveSessionWhenLeaveSessionThenStateIsIdleAndSessionFinishedIsSent() {
        // Given
        var machine = makeMachine(role: .host)
        machine.startWaitingForFriend()

        // When
        let commands = machine.leaveSession()

        // Then
        XCTAssertEqual(machine.state, .idle)
        XCTAssertEqual(commands, [.sessionFinished])
    }

    func testGivenAnyStateWhenReceivingSessionFinishedThenStateIsAbortedWithSessionEndedReason() {
        // Given
        var machine = makeMachine(role: .guest)
        machine.startWaitingForFriend()

        // When
        machine.receive(.sessionFinished)

        // Then
        XCTAssertEqual(machine.state, .aborted(reason: .sessionEnded))
    }

    func testGivenAnyStateWhenReceivingSessionAbortedThenStateMirrorsNonRetryReason() {
        // Given
        var machine = makeMachine(role: .guest)
        machine.startWaitingForFriend()

        // When
        machine.receive(.sessionAborted(reason: .disconnected))

        // Then
        XCTAssertEqual(machine.state, .aborted(reason: .disconnected))
    }

    func testGivenRetryAbortCommandWhenReceivingThenStateIsRetryTimedOut() {
        // Given
        var machine = finishedMachine(role: .guest)
        machine.retryTapped()

        // When
        machine.receive(.sessionAborted(reason: .retryTimedOut))

        // Then
        XCTAssertEqual(machine.state, .retryTimedOut)
    }

    // MARK: - Helpers

    private func finishedMachine(role: SharePlayPlayerRole) -> SharePlayMatchStateMachine {
        var machine = makeMachine(role: role)
        machine.startWaitingForFriend()
        if role == .host {
            machine.hostStartRound(difficulty: .fast)
        } else {
            machine.receive(.roundStart(startAt: fixedNow, difficulty: .fast))
        }
        machine.beginRound()
        machine.localPlayerEliminated(finalScore: 25)
        machine.receive(.playerEliminated(finalScore: 25))
        return machine
    }
}
