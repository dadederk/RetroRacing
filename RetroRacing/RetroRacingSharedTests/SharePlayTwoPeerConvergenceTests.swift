//
//  SharePlayTwoPeerConvergenceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 22/07/2026.
//

import XCTest
@testable import RetroRacingShared

/// Integration-style tests with a mocked transport: two `SharePlayMatchStateMachine` instances
/// (host + guest) exchange commands by relaying each side's returned commands directly into the
/// other's `receive(_:)`, exactly as `GroupSessionCoordinator` relays `SharePlayMatchCommand`
/// values over a real `GroupSessionMessenger`. This proves both simulated peers converge on
/// identical state without any dependency on `GroupActivities` (which cannot be constructed in a
/// unit test), satisfying the plan's "mocked-messenger integration test proving both peers
/// converge to the same terminal state" requirement.
final class SharePlayTwoPeerConvergenceTests: XCTestCase {

    private let fixedNow = Date(timeIntervalSinceReferenceDate: 2_000)

    private func makeMachine(role: SharePlayPlayerRole) -> SharePlayMatchStateMachine {
        SharePlayMatchStateMachine(localRole: role, countdownDuration: 3, retryTimeout: 30, clock: { self.fixedNow })
    }

    func testGivenTwoPeersWhenExchangingFullMatchLifecycleThenBothConvergeOnIdenticalFinishedResult() {
        // Given
        var host = makeMachine(role: .host)
        var guest = makeMachine(role: .guest)

        // When: session handshake (each side announces readiness to the other)
        relay(host.startWaitingForFriend(), from: &host, to: &guest)
        relay(guest.startWaitingForFriend(), from: &guest, to: &host)

        // Then: both sides know the other participant is present
        XCTAssertTrue(host.isRemoteReady)
        XCTAssertTrue(guest.isRemoteReady)

        // When: the host starts the authoritative countdown
        relay(host.hostStartRound(difficulty: .fast), from: &host, to: &guest)

        // Then: both machines share the identical countdown state
        XCTAssertEqual(host.state, guest.state)

        // When: the countdown elapses locally on both devices
        host.beginRound()
        guest.beginRound()

        // Then
        XCTAssertEqual(host.state, .inRound(difficulty: .fast, localScore: 0, remoteScore: 0, remoteLives: 3))
        XCTAssertEqual(guest.state, .inRound(difficulty: .fast, localScore: 0, remoteScore: 0, remoteLives: 3))

        // When: each device mirrors its own live score to the other
        relay(host.updateLocalScore(12, lives: 3), from: &host, to: &guest)
        relay(guest.updateLocalScore(9, lives: 2), from: &guest, to: &host)

        // Then: each side sees its own score locally and the opponent's mirrored score
        XCTAssertEqual(host.state, .inRound(difficulty: .fast, localScore: 12, remoteScore: 9, remoteLives: 2))
        XCTAssertEqual(guest.state, .inRound(difficulty: .fast, localScore: 9, remoteScore: 12, remoteLives: 3))

        // When: the guest is eliminated first
        relay(guest.localPlayerEliminated(finalScore: 9), from: &guest, to: &host)

        // Then: the guest waits with a live view of the still-racing host's score
        XCTAssertEqual(guest.state, .waitingAfterLocalLoss(remoteScore: 12, localFinalScore: 9))

        // When: the host keeps racing and mirrors a further score update
        relay(host.updateLocalScore(15, lives: 1), from: &host, to: &guest)

        // Then: the waiting guest's live opponent score updates accordingly
        XCTAssertEqual(guest.state, .waitingAfterLocalLoss(remoteScore: 15, localFinalScore: 9))

        // When: the host is eliminated too, completing the round
        relay(host.localPlayerEliminated(finalScore: 15), from: &host, to: &guest)

        // Then: both machines converge on the exact same mirrored result and outcome
        let expectedResult = SharePlayRoundResult(hostScore: 15, guestScore: 9, difficulty: .fast)
        XCTAssertEqual(host.state, .finished(expectedResult))
        XCTAssertEqual(guest.state, .finished(expectedResult))
        XCTAssertEqual(expectedResult.localOutcome(for: .host), .won)
        XCTAssertEqual(expectedResult.localOutcome(for: .guest), .lost)
    }

    func testGivenTwoPeersAtFinishedStateWhenBothRetryThenBothConvergeOnWaitingForFriend() {
        // Given
        var host = makeMachine(role: .host)
        var guest = makeMachine(role: .guest)
        playFullRoundToFinished(host: &host, guest: &guest)

        // When: both players independently confirm the rematch
        relay(host.retryTapped(), from: &host, to: &guest)
        relay(guest.retryTapped(), from: &guest, to: &host)

        // Then: both machines reset to waiting for the next round in lockstep
        XCTAssertEqual(host.state, .waitingForFriend)
        XCTAssertEqual(guest.state, .waitingForFriend)
    }

    func testGivenGuestConfirmsRetryLastWhenBothReadyThenHostCanStartNextCountdown() {
        // Given
        var host = makeMachine(role: .host)
        var guest = makeMachine(role: .guest)
        playFullRoundToFinished(host: &host, guest: &guest)

        // When: host confirms first, then guest confirms last
        relay(host.retryTapped(), from: &host, to: &guest)
        relay(guest.retryTapped(), from: &guest, to: &host)

        // Then: both peers are ready for the next round and the host can start the countdown
        XCTAssertEqual(host.state, .waitingForFriend)
        XCTAssertEqual(guest.state, .waitingForFriend)
        let commands = host.hostStartRound(difficulty: .fast)
        XCTAssertEqual(commands.count, 1)
    }

    func testGivenOnlyOnePeerRetriesWhenDeadlineElapsesThenBothConvergeOnRetryTimedOut() {
        // Given
        var host = makeMachine(role: .host)
        var guest = makeMachine(role: .guest)
        playFullRoundToFinished(host: &host, guest: &guest)

        // When: only the host confirms the rematch, and the 30s deadline elapses on both devices
        relay(host.retryTapped(), from: &host, to: &guest)
        host.retryTimeoutElapsed()
        guest.retryTimeoutElapsed()

        // Then: both machines converge on the timed-out state despite the guest never confirming
        XCTAssertEqual(host.state, .retryTimedOut)
        XCTAssertEqual(guest.state, .retryTimedOut)
    }

    // MARK: - Helpers

    /// Simulates a mocked `GroupSessionMessenger`: every command a peer produces is delivered
    /// directly to the other peer's `receive(_:)`.
    private func relay(
        _ commands: [SharePlayMatchCommand],
        from sender: inout SharePlayMatchStateMachine,
        to receiver: inout SharePlayMatchStateMachine
    ) {
        for command in commands {
            _ = receiver.receive(command)
        }
    }

    private func playFullRoundToFinished(
        host: inout SharePlayMatchStateMachine,
        guest: inout SharePlayMatchStateMachine
    ) {
        relay(host.startWaitingForFriend(), from: &host, to: &guest)
        relay(guest.startWaitingForFriend(), from: &guest, to: &host)
        relay(host.hostStartRound(difficulty: .fast), from: &host, to: &guest)
        host.beginRound()
        guest.beginRound()
        relay(guest.localPlayerEliminated(finalScore: 9), from: &guest, to: &host)
        relay(host.localPlayerEliminated(finalScore: 15), from: &host, to: &guest)
    }
}
