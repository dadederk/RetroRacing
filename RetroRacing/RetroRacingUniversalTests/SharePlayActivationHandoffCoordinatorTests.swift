//
//  SharePlayActivationHandoffCoordinatorTests.swift
//  RetroRacingUniversalTests
//
//  Created by Dani Devesa on 31/07/2026.
//

import Testing
import RetroRacingShared
@testable import RetroRacingUniversal

@MainActor
struct SharePlayActivationHandoffCoordinatorTests {
    @Test func testGivenPendingActivationWhenPlayWithFriendsIsTappedAgainThenDuplicateRequestIsIgnored() async {
        // Given
        let service = MockSharePlayMatchServiceForHandoff()
        let coordinator = makeCoordinator(service: service, isEligibleForGroupSession: { false })

        // When
        coordinator.handlePlayWithFriendsRequest(currentState: .idle)
        _ = await waitUntil {
            coordinator.sharingPresentation != nil
        }
        coordinator.handlePlayWithFriendsRequest(currentState: .idle)

        // Then
        let events = await service.recordedEvents()
        #expect(events.filter(\.isPrepareHostActivation).count == 1)
    }

    @Test func testGivenEligibleGroupSessionWhenPlayWithFriendsIsTappedThenActivityActivatesDirectly() async {
        // Given
        let service = MockSharePlayMatchServiceForHandoff()
        let coordinator = makeCoordinator(service: service, isEligibleForGroupSession: { true })

        // When
        coordinator.handlePlayWithFriendsRequest(currentState: .idle)
        _ = await waitUntil {
            await service.recordedEvents().contains(.activatePendingHostSession(reason: .eligibleMenuRequest))
        }

        // Then
        let events = await service.recordedEvents()
        #expect(events.contains(.prepareHostActivation))
        #expect(events.contains(.activatePendingHostSession(reason: .eligibleMenuRequest)))
        #expect(coordinator.sharingPresentation == nil)
    }

    @Test func testGivenIneligibleGroupSessionWhenPlayWithFriendsIsTappedThenSharingPresentationIsCreated() async {
        // Given
        let service = MockSharePlayMatchServiceForHandoff()
        let coordinator = makeCoordinator(service: service, isEligibleForGroupSession: { false })

        // When
        coordinator.handlePlayWithFriendsRequest(currentState: .idle)
        let didPresent = await waitUntil {
            coordinator.sharingPresentation != nil
        }

        // Then
        let events = await service.recordedEvents()
        #expect(didPresent)
        #expect(events == [.prepareHostActivation])
    }

    @Test func testGivenSuccessfulSharingControllerHandoffWhenConversationBecomesEligibleThenRecoveryActivatesOnce() async {
        // Given
        let service = MockSharePlayMatchServiceForHandoff()
        let eligibilityProbe = SharePlayEligibilityProbe(isEligible: false)
        let coordinator = makeCoordinator(
            service: service,
            isEligibleForGroupSession: { eligibilityProbe.isEligible },
            timing: .testFast
        )

        // When
        coordinator.handlePlayWithFriendsRequest(currentState: .idle)
        _ = await waitUntil {
            coordinator.sharingPresentation != nil
        }
        eligibilityProbe.isEligible = true
        coordinator.handleSharePlaySharingSucceeded(
            isSharePlayIdle: true,
            isMenuPresented: true,
            shouldStartGame: false
        )
        _ = await waitUntil {
            await service.recordedEvents().contains(
                .activatePendingHostSession(reason: .sharingControllerHandoffRecovery)
            )
        }
        try? await Task.sleep(nanoseconds: 5_000_000)

        // Then
        let recoveryActivations = await service.recordedEvents().filter {
            $0 == .activatePendingHostSession(reason: .sharingControllerHandoffRecovery)
        }
        #expect(recoveryActivations.count == 1)
    }

    @Test func testGivenSharingControllerIsDismissedWhenSharePlayIsIdleThenPendingActivationIsCancelled() async {
        // Given
        let service = MockSharePlayMatchServiceForHandoff()
        let coordinator = makeCoordinator(service: service, isEligibleForGroupSession: { false })

        // When
        coordinator.handlePlayWithFriendsRequest(currentState: .idle)
        _ = await waitUntil {
            coordinator.sharingPresentation != nil
        }
        coordinator.handleSharePlaySharingUserDismissed(isSharePlayIdle: true)
        _ = await waitUntil {
            await service.recordedEvents().contains(.cancelHostActivation(reason: .sharingControllerDismissed))
        }

        // Then
        #expect(coordinator.isActivationPending == false)
        #expect(coordinator.sharingPresentation == nil)
    }

    @Test func testGivenPendingActivationWhenSharePlayStateArrivesThenRequestIsCleared() async {
        // Given
        let service = MockSharePlayMatchServiceForHandoff()
        let coordinator = makeCoordinator(service: service, isEligibleForGroupSession: { false })

        // When
        coordinator.handlePlayWithFriendsRequest(currentState: .idle)
        _ = await waitUntil {
            coordinator.sharingPresentation != nil
        }
        coordinator.clearActivationRequest(reason: .sharePlayStateArrived)

        // Then
        #expect(coordinator.isActivationPending == false)
    }

    @Test func testGivenActivatedSessionDoesNotArriveWhenHandoffTimesOutThenPendingActivationIsCancelled() async {
        // Given
        let service = MockSharePlayMatchServiceForHandoff()
        let coordinator = makeCoordinator(
            service: service,
            isEligibleForGroupSession: { true },
            timing: .testFast
        )

        // When
        coordinator.handlePlayWithFriendsRequest(currentState: .idle)
        _ = await waitUntil {
            await service.recordedEvents().contains(.cancelHostActivation(reason: .sessionHandoffTimeout))
        }

        // Then
        #expect(coordinator.isActivationPending == false)
        #expect(coordinator.sharingPresentation == nil)
    }
}

@MainActor
private final class SharePlayEligibilityProbe {
    var isEligible: Bool

    init(isEligible: Bool) {
        self.isEligible = isEligible
    }
}

private extension SharePlayActivationHandoffCoordinatorTests {
    func makeCoordinator(
        service: MockSharePlayMatchServiceForHandoff,
        isSharePlayAvailable: Bool = true,
        isEligibleForGroupSession: @escaping @MainActor () -> Bool,
        timing: SharePlayActivationHandoffTiming = .standard
    ) -> SharePlayActivationHandoffCoordinator {
        SharePlayActivationHandoffCoordinator(
            sharePlayMatchService: service,
            isSharePlayAvailable: isSharePlayAvailable,
            isEligibleForGroupSession: isEligibleForGroupSession,
            timing: timing
        )
    }

    func waitUntil(
        timeoutNanoseconds: UInt64 = 200_000_000,
        pollNanoseconds: UInt64 = 1_000_000,
        condition: @escaping @MainActor () async -> Bool
    ) async -> Bool {
        var elapsedNanoseconds: UInt64 = 0
        while elapsedNanoseconds < timeoutNanoseconds {
            if await condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: pollNanoseconds)
            elapsedNanoseconds += pollNanoseconds
        }
        return await condition()
    }
}

private extension SharePlayActivationHandoffTiming {
    static let testFast = SharePlayActivationHandoffTiming(
        pollNanoseconds: 1_000_000,
        settleNanoseconds: 1_000_000,
        timeoutNanoseconds: 4_000_000
    )
}

private actor MockSharePlayMatchServiceForHandoff: SharePlayMatchService {
    enum Event: Equatable {
        case prepareHostActivation
        case activatePendingHostSession(reason: SharePlayHostActivationReason)
        case cancelHostActivation(reason: SharePlayHostActivationReason)

        var isPrepareHostActivation: Bool {
            self == .prepareHostActivation
        }
    }

    private var events: [Event] = []
    private var stateChangeHandler: (@Sendable (SharePlayUIState) async -> Void)?
    var prepareHostActivationResult = true
    var activatePendingHostSessionResult = true

    func recordedEvents() -> [Event] {
        events
    }

    func setStateChangeHandler(
        _ handler: @escaping @Sendable (SharePlayUIState) async -> Void
    ) async {
        stateChangeHandler = handler
    }

    func prepareHostActivation() async -> Bool {
        events.append(.prepareHostActivation)
        return prepareHostActivationResult
    }

    func activatePendingHostSession(reason: SharePlayHostActivationReason) async -> Bool {
        events.append(.activatePendingHostSession(reason: reason))
        return activatePendingHostSessionResult
    }

    func cancelHostActivation(reason: SharePlayHostActivationReason) async {
        events.append(.cancelHostActivation(reason: reason))
    }

    func observeIncomingSessions() async {}

    func hostStartRoundIfReady(difficulty: GameDifficulty) async {}

    func updateLocalScore(_ score: Int, lives: Int) async {}

    func reportLocalElimination(finalScore: Int) async {}

    func retry() async {}

    func leaveSession() async {}
}
